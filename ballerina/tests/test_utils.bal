// Copyright (c) 2025 WSO2 LLC. (http://www.wso2.org).
//
// WSO2 Inc. licenses this file to you under the Apache License,
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

import ballerina/test;

isolated function getExpectedParameterSchema(string message) returns map<json> {
    if message.startsWith("Evaluate this") {
        return expectedParameterSchemaStringForRateBlog6;
    }

    if message.startsWith("Rate this blog") {
        return expectedParameterSchemaStringForRateBlog;
    }

    if message.startsWith("Please rate this blogs") {
        return expectedParameterSchemaStringForRateBlog5;
    }

    if message.startsWith("Please rate this blog") {
        return expectedParameterSchemaStringForRateBlog2;
    }

    if message.startsWith("What is 1 + 1?") {
        return expectedParameterSchemaStringForRateBlog3;
    }

    if message.startsWith("Tell me") {
        return expectedParameterSchemaStringForRateBlog4;
    }

    if message.startsWith("How would you rate this blog content") {
        return expectedParameterSchemaStringForRateBlog;
    }

    if message.startsWith("How would you rate this text blogs") {
        return expectedParameterSchemaStringForRateBlog5;
    }

    if message.startsWith("How would you rate this text blog") {
        return expectedParameterSchemaStringForRateBlog2;
    }

    if message.startsWith("How do you rate this blog") {
        return expectedParameterSchemaStringForRateBlog7;
    }

    if message.startsWith("How would you rate this blog") {
        return expectedParameterSchemaStringForRateBlog2;
    }

    if message.startsWith("How would you rate these text chunks") {
        return expectedParameterSchemaStringForRateBlog5;
    }

    if message.startsWith("How would you rate this text chunk") {
        return expectedParameterSchemaStringForRateBlog;
    }

    if message.startsWith("What's the output of the Ballerina code below?") {
        return expectedParamterSchemaStringForBalProgram;
    }

    if message.startsWith("Which country") {
        return expectedParamterSchemaStringForCountry;
    }

    if message.startsWith("Who is a popular sportsperson") {
        return {
            "type": "object",
            "properties": {
                "result": {
                    "oneOf": [
                        {
                            "type": "object",
                            "required": ["firstName", "middleName", "lastName", "yearOfBirth", "sport"],
                            "properties": {
                                "firstName": {"type": "string"},
                                "middleName": {"oneOf": [{"type": "string"}, {"type": "null"}]},
                                "lastName": {"type": "string"},
                                "yearOfBirth": {"type": "integer"},
                                "sport": {"type": "string"}
                            }
                        },
                        {"type": "null"}
                    ]
                }
            }
        };
    }

    if message.startsWith("Give me a random joke about cricketers") {
        return expectedParameterSchemaForRecUnionBasicType;
    }

    if message.startsWith("Give me a random joke") {
        return {"type": "object", "properties": {"result": {"anyOf": [{"type": "string"}, {"type": "null"}]}}};
    }

    if message.startsWith("Name a random world class cricketer in India") {
        return expectedParameterSchemaForRecUnionNull;
    }

    if message.startsWith("Name 10 world class cricketers in India") {
        return expectedParameterSchemaForArrayOnly;
    }

    if message.startsWith("Name 10 world class cricketers as string") {
        return expectedParameterSchemaForArrayUnionBasicType;
    }

    if message.startsWith("Name top 10 world class cricketers") {
        return expectedParameterSchemaForArrayUnionRec;
    }

    if message.startsWith("Name a random world class cricketer") {
        return expectedParameterSchemaForArrayUnionRec;
    }

    if message.startsWith("Name 10 world class cricketers") {
        return expectedParamSchemaForArrayUnionNull;
    }

    return {};
}

isolated function getTheMockLLMResult(string message) returns string {
    if message.startsWith("Evaluate this") {
        return string `{"result": [9, 1]}`;
    }

    if message.startsWith("Rate this blog") {
        return "{\"result\": 4}";
    }

    if message.startsWith("Please rate this blogs") {
        return string `{"result": [${review}, ${review}]}`;
    }

    if message.startsWith("Please rate this blog") {
        return review;
    }

    if message.startsWith("How would you rate these text chunks") {
        return string `{"result": [${review}, ${review}]}`;
    }

    if message.startsWith("How would you rate this text chunk") {
        return {result: 4}.toJsonString();
    }

    if message.startsWith("What is 1 + 1?") {
        return "{\"result\": 2}";
    }

    if message.startsWith("Tell me") {
        return "{\"result\": [{\"name\": \"Virat Kohli\", \"age\": 33}, {\"name\": \"Kane Williamson\", \"age\": 30}]}";
    }

    if message.startsWith("What's the output of the Ballerina code below?") {
        return "{\"result\": 30}";
    }

    if message.startsWith("Which country") {
        return "{\"result\": \"Sri Lanka\"}";
    }

    if message.startsWith("Who is a popular sportsperson") {
        return "{\"result\": {\"firstName\": \"Simone\", \"middleName\": null, " +
            "\"lastName\": \"Biles\", \"yearOfBirth\": 1997, \"sport\": \"Gymnastics\"}}";
    }

    if message.startsWith("How would you rate this blog content") {
        return "{\"result\": 4}";
    }

    if message.startsWith("How do you rate this blog") {
        return "{\"result\": 4}";
    }

    if message.startsWith("How would you rate this text blogs") {
        return string `{"result": [${review}, ${review}]}`;
    }

    if message.startsWith("How would you rate this text blog") {
        return review;
    }

    if message.startsWith("How would you rate this blog") {
        return review;
    }

    if message.startsWith("Name a random world class cricketer in India") {
        return "{\"result\": {\"name\": \"Sanga\"}}";
    }

    if message.startsWith("Name a random world class cricketer") {
        return "{\"result\": {\"name\": \"Sanga\"}}";
    }

    if message.startsWith("Name 10 world class cricketers") {
        return "{\"result\": [{\"name\": \"Virat Kohli\"}, {\"name\": \"Joe Root\"}, {\"name\": \"Steve Smith\"}, {\"name\": \"Kane Williamson\"}, {\"name\": \"Babar Azam\"}, {\"name\": \"Ben Stokes\"}, {\"name\": \"Jasprit Bumrah\"}, {\"name\": \"Pat Cummins\"}, {\"name\": \"Shaheen Afridi\"}, {\"name\": \"Rashid Khan\"}]}";
    }

    if message.startsWith("Name top 10 world class cricketers") {
        return "{\"result\": [{\"name\": \"Virat Kohli\"}, {\"name\": \"Joe Root\"}, {\"name\": \"Steve Smith\"}, {\"name\": \"Kane Williamson\"}, {\"name\": \"Babar Azam\"}, {\"name\": \"Ben Stokes\"}, {\"name\": \"Jasprit Bumrah\"}, {\"name\": \"Pat Cummins\"}, {\"name\": \"Shaheen Afridi\"}, {\"name\": \"Rashid Khan\"}]}";
    }

    if message.startsWith("Give me a random joke") {
        return "{\"result\": \"This is a random joke\"}";
    }

    return "INVALID";
}

isolated function getTestServiceResponse(string content) returns DeepSeekChatCompletionResponse =>
    {
    id: "test-id",
    choices: [
        {
            message: {
                role: "assistant",
                tool_calls: [
                    {
                        id: "tool-call-id",
                        'type: "function",
                        'function: {
                            name: GET_RESULTS_TOOL,
                            arguments: getTheMockLLMResult(content)
                        }
                    }
                ]
            }
        }
    ]
};

isolated function getExpectedPrompt(string message) returns json {
    if message.startsWith("Rate this blog") {
        return expectedPromptStringForRateBlog;
    }

    if message.startsWith("Evaluate this") {
        return expectedPromptStringForRateBlog10;
    }

    if message.startsWith("Please rate this blogs") {
        return expectedPromptStringForRateBlog7;
    }

    if message.startsWith("Please rate this blog") {
        return expectedPromptStringForRateBlog2;
    }

    if message.startsWith("How would you rate these text chunks") {
        return expectedContentPartsForTextChunkArray;
    }

    if message.startsWith("How would you rate this text chunk") {
        return expectedContentPartsForTextChunk;
    }

    if message.startsWith("What is 1 + 1?") {
        return expectedPromptStringForRateBlog3;
    }

    if message.startsWith("Tell me") {
        return expectedPromptStringForRateBlog4;
    }

    if message.startsWith("How would you rate this blog content") {
        return expectedPromptStringForRateBlog5;
    }

    if message.startsWith("How do you rate this blog") {
        return expectedPromptStringForRateBlog11;
    }

    if message.startsWith("How would you rate this text blogs") {
        return expectedPromptStringForRateBlog9;
    }

    if message.startsWith("How would you rate this text blog") {
        return expectedPromptStringForRateBlog8;
    }

    if message.startsWith("How would you rate this blog") {
        return expectedPromptStringForRateBlog6;
    }

    if message.startsWith("What's the output of the Ballerina code below?") {
        return expectedPromptStringForBalProgram;
    }

    if message.startsWith("Which country") {
        return expectedPromptStringForCountry;
    }

    if message.startsWith("Who is a popular sportsperson") {
        return string `Who is a popular sportsperson that was 
        born in the decade starting from 1990 with Simone in 
        their name?`;
    }

    if message.startsWith("Name 10 world class cricketers in India") {
        return "Name 10 world class cricketers in India";
    }

    if message.startsWith("Name 10 world class cricketers as string") {
        return "Name 10 world class cricketers as string";
    }

    if message.startsWith("Name 10 world class cricketers") {
        return "Name 10 world class cricketers";
    }

    if message.startsWith("Name top 10 world class cricketers") {
        return "Name top 10 world class cricketers";
    }

    if message.startsWith("Name a random world class cricketer in India") {
        return "Name a random world class cricketer in India";
    }

    if message.startsWith("Name a random world class cricketer") {
        return "Name a random world class cricketer";
    }

    if message.startsWith("Give me a random joke about cricketers") {
        return "Give me a random joke about cricketers";
    }

    if message.startsWith("Give me a random joke") {
        return "Give me a random joke";
    }

    return "INVALID";
}

isolated function getMockChatResponse(string? content, string? reasoningContent, json[]? toolCalls = ()) returns json =>
    {
    id: "test-id",
    choices: [
        {
            message: {
                role: "assistant",
                content,
                reasoning_content: reasoningContent,
                tool_calls: toolCalls
            },
            finish_reason: toolCalls is () ? "stop" : "tool_calls"
        }
    ],
    usage: {prompt_tokens: 10, completion_tokens: 20}
};

isolated function getJsonOutputModeResponse(map<json> payload, json[] messages) returns json|error {
    test:assertEquals(payload["response_format"], {"type": "json_object"});
    test:assertFalse(payload.hasKey("tool_choice"), "Thinking mode does not support named tool choices");
    test:assertEquals(payload["tools"], ());
    test:assertEquals(messages.length(), 2);

    map<json> systemMessage = check messages[0].ensureType();
    map<json> userMessage = check messages[1].ensureType();
    test:assertEquals(systemMessage["role"], "system");
    test:assertEquals(userMessage["role"], "user");

    string content = check userMessage["content"].ensureType();
    test:assertEquals(content, getExpectedPrompt(content));
    string instruction = check systemMessage["content"].ensureType();
    int? schemaIndex = instruction.indexOf(JSON_SCHEMA_LABEL);
    if schemaIndex is () {
        test:assertFail("Expected the JSON schema in the system message");
    }
    json schema = check instruction.substring(schemaIndex + JSON_SCHEMA_LABEL.length()).fromJsonString();
    test:assertEquals(schema, getExpectedParameterSchema(content), string `Test failed for prompt:- ${content}`);
    return getMockChatResponse(getTheMockLLMResult(content), "Reasoning about the response.");
}

isolated function getToolLoopResponse(map<json> payload, json[] messages) returns json|error {
    test:assertEquals(payload["model"], DEEPSEEK_FLASH);
    test:assertEquals(payload["max_tokens"], DEFAULT_MAX_TOKEN_COUNT);
    test:assertEquals(payload["thinking"], {"type": "enabled"});
    test:assertEquals(payload["reasoning_effort"], "high");
    test:assertFalse(payload.hasKey("tool_choice"));
    json[] tools = check payload["tools"].ensureType();
    test:assertEquals(tools.length(), 2);

    // Thinking mode requires the `reasoning_content` of every previous assistant turn when tools are present.
    string[] reasoningContents = [];
    foreach json message in messages {
        map<json> chatMessage = check message.ensureType();
        if chatMessage["role"] == "assistant" {
            test:assertTrue(chatMessage.hasKey("reasoning_content"),
                    string `Missing reasoning_content in the assistant message: ${chatMessage.toJsonString()}`);
            string reasoningContent = check chatMessage["reasoning_content"].ensureType();
            reasoningContents.push(reasoningContent);
        }
    }

    map<json> lastMessage = check messages[messages.length() - 1].ensureType();
    if reasoningContents.length() == 0 {
        return getMockChatResponse("", TOOL_CALL_REASONING, [
            {id: "call_weather", 'type: "function", 'function: {name: "getWeather", arguments: "{\"city\": \"Colombo\"}"}},
            {id: "call_time", 'type: "function", 'function: {name: "getTime", arguments: "{\"city\": \"Colombo\"}"}}
        ]);
    }
    if lastMessage["role"] == "tool" {
        test:assertEquals(reasoningContents, [TOOL_CALL_REASONING, TOOL_CALL_REASONING]);
        return getMockChatResponse(WEATHER_ANSWER, WEATHER_ANSWER_REASONING);
    }
    test:assertEquals(reasoningContents, [TOOL_CALL_REASONING, TOOL_CALL_REASONING, WEATHER_ANSWER_REASONING]);
    return getMockChatResponse(FORECAST_ANSWER, "The user asks about tomorrow.");
}
