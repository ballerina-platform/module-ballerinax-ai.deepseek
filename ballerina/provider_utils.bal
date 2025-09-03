// Copyright (c) 2025 WSO2 LLC (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/ai;
import ballerina/http;
import ballerina/lang.runtime;

type ResponseSchema record {|
    map<json> schema;
    boolean isOriginallyJsonObject = true;
|};

const JSON_CONVERSION_ERROR = "FromJsonStringError";
const CONVERSION_ERROR = "ConversionError";
const ERROR_MESSAGE = "Error occurred while attempting to parse the response from the " +
    "LLM as the expected type. Retrying and/or validating the prompt could fix the response.";
const RESULT = "result";
const GET_RESULTS_TOOL = "getResults";
const FUNCTION = "function";
const NO_RELEVANT_RESPONSE_FROM_THE_LLM = "No relevant response from the LLM";

isolated function generateJsonObjectSchema(map<json> schema) returns ResponseSchema {
    string[] supportedMetaDataFields = ["$schema", "$id", "$anchor", "$comment", "title", "description"];

    if schema["type"] == "object" {
        return {schema};
    }

    map<json> updatedSchema = map from var [key, value] in schema.entries()
        where supportedMetaDataFields.indexOf(key) is int
        select [key, value];

    updatedSchema["type"] = "object";
    map<json> content = map from var [key, value] in schema.entries()
        where supportedMetaDataFields.indexOf(key) !is int
        select [key, value];

    updatedSchema["properties"] = {[RESULT]: content};

    return {schema: updatedSchema, isOriginallyJsonObject: false};
}

isolated function parseResponseAsType(string resp,
        typedesc<anydata> expectedResponseTypedesc, boolean isOriginallyJsonObject) returns anydata|error {
    if !isOriginallyJsonObject {
        map<json> respContent = check resp.fromJsonStringWithType();
        anydata|error result = trap respContent[RESULT].fromJsonWithType(expectedResponseTypedesc);
        if result is error {
            return handleParseResponseError(result);
        }
        return result;
    }

    anydata|error result = resp.fromJsonStringWithType(expectedResponseTypedesc);
    if result is error {
        return handleParseResponseError(result);
    }
    return result;
}

isolated function getExpectedResponseSchema(typedesc<anydata> expectedResponseTypedesc) returns ResponseSchema|ai:Error {
    // Restricted at compile-time for now.
    typedesc<json> td = checkpanic expectedResponseTypedesc.ensureType();
    return generateJsonObjectSchema(check generateJsonSchemaForTypedescAsJson(td));
}

isolated function getGetResultsToolChoice() returns DeepSeekToolChoice => {
    'type: FUNCTION,
    'function: {
        name: GET_RESULTS_TOOL
    }
};

isolated function getGetResultsTool(map<json> parameters) returns DeepseekTool[]|error  =>
    [
        {
            'type: FUNCTION,
            'function: {
                name: GET_RESULTS_TOOL,
                parameters: parameters,
                description: "Tool to call with the response from a large language model (LLM) for a user prompt."
            }
        }
    ];

isolated function generateChatCreationContent(ai:Prompt prompt) returns string|ai:Error {
    string[] & readonly strings = prompt.strings;
    anydata[] insertions = prompt.insertions;
    string promptStr = strings[0];
    foreach int i in 0 ..< insertions.length() {
        string str = strings[i + 1];
        anydata insertion = insertions[i];

        if insertion is ai:TextDocument {
            promptStr += insertion.content + " " + str;
            continue;
        }

        if insertion is ai:TextDocument[] {
            foreach ai:TextDocument doc in insertion {
                promptStr += doc.content  + " ";
                
            }
            promptStr += str;
            continue;
        }

        if insertion is ai:Document {
            return error ai:Error("Only Text Documents are currently supported.");
        }

        promptStr += insertion.toString() + str;
    }
    return promptStr.trim();
}

isolated function handleParseResponseError(error chatResponseError) returns error {
    string msg = chatResponseError.message();
    if msg.includes(JSON_CONVERSION_ERROR) || msg.includes(CONVERSION_ERROR) {
        return error(string `${ERROR_MESSAGE}`, chatResponseError);
    }
    return chatResponseError;
}

isolated function generateLlmResponse(http:Client llmClient, int maxTokens, DEEPSEEK_MODEL_NAMES modelType,
        decimal temperature, ai:GeneratorConfig generatorConfig, ai:Prompt prompt,
        typedesc<json> expectedResponseTypedesc) returns anydata|ai:Error {

    string content = check generateChatCreationContent(prompt);
    ResponseSchema responseSchema = check getExpectedResponseSchema(expectedResponseTypedesc);
    DeepseekTool[]|error tools = getGetResultsTool(responseSchema.schema);
    if tools is error {
        return error("Error in generated schema: " + tools.message());
    }

    DeepSeekChatRequestMessages[] messages = [<DeepseekChatUserMessage>{
        role: ai:USER,
        content
    }];

    DeepSeekChatCompletionRequest request = {
        messages,
        model: modelType,
        max_tokens: maxTokens,
        temperature,
        tools,
        toolChoice: getGetResultsToolChoice()
    };

    [int, decimal] [count, interval] = check getRetryConfigValues(generatorConfig);

    return getLlmResponseWithRetries(llmClient, request, expectedResponseTypedesc, responseSchema.isOriginallyJsonObject,
            count, interval);
}

isolated function getLlmResponseWithRetries(http:Client llmClient,
        DeepSeekChatCompletionRequest request,
        typedesc<anydata> expectedResponseTypedesc,
        boolean isOriginallyJsonObject, int retryCount, decimal retryInterval) returns anydata|ai:Error {

    DeepSeekChatCompletionResponse|error response = llmClient->/chat/completions.post(request);
    if response is error {
        return error ai:LlmConnectionError("Error while connecting to the model", response);
    }

    DeepseekChatResponseChoice[]? choices = response.choices;
    if choices is () || choices.length() == 0 {
        return error("No completion choices");
    }

    DeepseekChatResponseMessage message = choices[0].message;
    DeepseekChatResponseToolCall[]? toolCalls = message?.tool_calls;
    if toolCalls is ()  || toolCalls.length() == 0 {
        return error(NO_RELEVANT_RESPONSE_FROM_THE_LLM);
    }

    DeepseekChatResponseToolCall toolCall = toolCalls[0];
    map<json>|error arguments = toolCall.'function.arguments.fromJsonStringWithType();
    if arguments is error {
        return error(NO_RELEVANT_RESPONSE_FROM_THE_LLM);
    }

    anydata|error result = handleResponseWithExpectedType(arguments, isOriginallyJsonObject, expectedResponseTypedesc);
    DeepSeekChatRequestMessages[] history = request.messages;
    history.push(message);

    if result is error && retryCount > 0 {
        string toolId = toolCall.id;
        string functionName = toolCall.'function.name;
        string|error repairMessage = getRepairMessage(result, toolId, functionName);

        if repairMessage is error {
            return error("Failed to generate a valid repair message: " + repairMessage.message());
        }

        history.push(<DeepseekChatUserMessage>{
            role: ai:USER,
            content: repairMessage
        });

        runtime:sleep(retryInterval);
        return getLlmResponseWithRetries(llmClient, request, expectedResponseTypedesc, isOriginallyJsonObject,
                retryCount - 1, retryInterval);
    }

    if result is anydata {
        return result;
    }

    return error ai:LlmInvalidGenerationError(string `Invalid value returned from the LLM Client, expected: '${
            expectedResponseTypedesc.toBalString()}', found '${result.toBalString()}'`);
}

isolated function handleResponseWithExpectedType(map<json> arguments, boolean isOriginallyJsonObject,
        typedesc<anydata> expectedResponseTypedesc) returns anydata|error {
    anydata|error res = parseResponseAsType(arguments.toJsonString(), expectedResponseTypedesc,
            isOriginallyJsonObject);
    if res is error {
        return res;
    }

    anydata|error result = res.ensureType(expectedResponseTypedesc);
    if result is error {
        return error(string `LLM response does not match the expected type '${expectedResponseTypedesc.toBalString()}'`, cause = result);
    }
    return result;
}

isolated function getRepairMessage(error e, string toolId, string functionName) returns string|error {
    error? cause = e.cause();
    string errorMessage = (cause is ()) ? e.message() : cause.toString();

    return string `The tool call with ID '${toolId}' for the function '${functionName}' failed.
        Error: ${errorMessage}
        You must correct the function arguments based on this error and respond with a valid tool call.`;
}

isolated function getRetryConfigValues(ai:GeneratorConfig generatorConfig) returns [int, decimal]|ai:Error {
    ai:RetryConfig? retryConfig = generatorConfig.retryConfig;
    if retryConfig != () {
        int count = retryConfig.count;
        decimal? interval = retryConfig.interval;

        if count < 0 {
            return error("Invalid retry count: " + count.toString());
        }
        if interval < 0d {
            return error("Invalid retry interval: " + interval.toString());
        }

        return [count, interval ?: 0d];
    }
    return [0, 0d];
}
