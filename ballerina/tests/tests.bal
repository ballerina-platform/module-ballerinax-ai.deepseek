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

import ballerina/ai;
import ballerina/test;

const SERVICE_URL = "http://localhost:8080/llm/deepseek";
const THINKING_SERVICE_URL = "http://localhost:8080/llm/thinking";
const API_KEY = "not-a-real-api-key";
const ERROR_MESSAGE = "Error occurred while attempting to parse the response from the LLM as the expected type. Retrying and/or validating the prompt could fix the response.";
const RUNTIME_SCHEMA_NOT_SUPPORTED_ERROR_MESSAGE = "Runtime schema generation is not yet supported";

final ModelProvider deepseekProvider = check new (API_KEY, DEEPSEEK_V4_PRO, SERVICE_URL, thinking = DISABLED);
final ModelProvider deepseekThinkingProvider = check new (API_KEY, serviceUrl = THINKING_SERVICE_URL);

@test:Config
function testGenerateMethodWithBasicReturnType() returns ai:Error? {
    int|error rating = deepseekProvider->generate(`Rate this blog out of 10.
        Title: ${blog1.title}
        Content: ${blog1.content}`);

    if rating is error {
        test:assertFail(rating.message());
    }
    test:assertEquals(rating, 4);
}

@test:Config
function testGenerateMethodWithBasicArrayReturnType() returns ai:Error? {
    int[]|error rating = deepseekProvider->generate(`Evaluate this blogs out of 10.
        Title: ${blog1.title}
        Content: ${blog1.content}

        Title: ${blog1.title}
        Content: ${blog1.content}`);

    if rating is error {
        test:assertFail(rating.message());
    }
    test:assertEquals(rating, [9, 1]);
}

@test:Config
function testGenerateMethodWithRecordReturnType() returns error? {
    Review|error result = deepseekProvider->generate(`Please rate this blog out of 10.
        Title: ${blog2.title}
        Content: ${blog2.content}`);
    if result is error {
        test:assertFail(result.message());
    }
    test:assertEquals(result, check review.fromJsonStringWithType(Review));
}

@test:Config
function testGenerateMethodWithTextDocument() returns ai:Error? {
    ai:TextDocument blog = {
        content: string `Title: ${blog1.title} Content: ${blog1.content}`
    };
    int maxScore = 10;

    int|error rating = deepseekProvider->generate(`How would you rate this ${"blog"} content out of ${maxScore}. ${blog}.`);
    if rating is error {
        test:assertFail(rating.message());
    }
    test:assertEquals(rating, 4);
}

@test:Config
function testGenerateMethodWithTextDocument2() returns error? {
    ai:TextDocument blog = {
        content: string `Title: ${blog1.title} Content: ${blog1.content}`
    };
    int maxScore = 10;

    Review|error result = deepseekProvider->generate(`How would you rate this text blog out of ${maxScore}, ${blog}.`);
    if result is error {
        test:assertFail(result.message());
    }

    test:assertEquals(result, check review.fromJsonStringWithType(Review));
}

type ReviewArray Review[];

@test:Config
function testGenerateMethodWithTextDocumentArray() returns error? {
    ai:TextDocument blog = {
        content: string `Title: ${blog1.title} Content: ${blog1.content}`
    };
    ai:TextDocument[] blogs = [blog, blog];
    int maxScore = 10;
    Review r = check review.fromJsonStringWithType(Review);

    ReviewArray|error result = deepseekProvider->generate(`How would you rate this text blogs out of ${maxScore}. ${blogs}. Thank you!`);
    if result is error {
        test:assertFail(result.message());
    }
    test:assertEquals(result, [r, r]);
}

@test:Config
function testGenerateMethodWithRecordArrayReturnType() returns error? {
    int maxScore = 10;
    Review r = check review.fromJsonStringWithType(Review);

    ReviewArray|error result = deepseekProvider->generate(`Please rate this blogs out of ${maxScore}.
        [{Title: ${blog1.title}, Content: ${blog1.content}}, {Title: ${blog2.title}, Content: ${blog2.content}}]`);

    if result is error {
        test:assertFail(result.message());
    }
    test:assertEquals(result, [r, r]);
}

@test:Config
function testGenerateMethodWithInvalidBasicType() returns ai:Error? {
    boolean|error rating = deepseekProvider->generate(`What is ${1} + ${1}?`);
    test:assertTrue(rating is error);
    test:assertTrue((<error>rating).message().includes(ERROR_MESSAGE));
}

type ProductName record {|
    string name;
|};

@test:Config
function testGenerateMethodWithInvalidRecordType() returns ai:Error? {
    ProductName[]|map<string>|error rating = trap deepseekProvider->generate(
                `Tell me name and the age of the top 10 world class cricketers`);
    string msg = (<error>rating).message();
    test:assertTrue(rating is error);
    test:assertTrue(msg.includes(RUNTIME_SCHEMA_NOT_SUPPORTED_ERROR_MESSAGE),
            string `expected error message to contain: ${RUNTIME_SCHEMA_NOT_SUPPORTED_ERROR_MESSAGE}, but found ${msg}`);
}

type ProductNameArray ProductName[];

@test:Config
function testGenerateMethodWithInvalidRecordArrayType2() returns ai:Error? {
    ProductNameArray|error rating = deepseekProvider->generate(
                `Tell me name and the age of the top 10 world class cricketers`);
    test:assertTrue(rating is error);
    test:assertTrue((<error>rating).message().includes(ERROR_MESSAGE));
}

type Cricketers record {|
    string name;
|};

type Cricketers1 record {|
    string name;
|};

type Cricketers2 record {|
    string name;
|};

type Cricketers3 record {|
    string name;
|};

type Cricketers4 record {|
    string name;
|};

type Cricketers5 record {|
    string name;
|};

type Cricketers6 record {|
    string name;
|};

type Cricketers7 record {|
    string name;
|};

type Cricketers8 record {|
    string name;
|};

@test:Config
function testGenerateMethodWithStringUnionNull() returns error? {
    string? result = check deepseekProvider->generate(`Give me a random joke`);
    test:assertTrue(result is string);
}

@test:Config
function testGenerateMethodWithRecUnionBasicType() returns error? {
    Cricketers|string result = check deepseekProvider->generate(`Give me a random joke about cricketers`);
    test:assertTrue(result is string);
}

@test:Config
function testGenerateMethodWithRecUnionNull() returns error? {
    Cricketers1? result = check deepseekProvider->generate(`Name a random world class cricketer in India`);
    test:assertTrue(result is Cricketers1);
}

@test:Config
function testGenerateMethodWithArrayOnly() returns error? {
    Cricketers2[] result = check deepseekProvider->generate(`Name 10 world class cricketers in India`);
    test:assertTrue(result is Cricketers2[]);
}

@test:Config
function testGenerateMethodWithArrayUnionBasicType() returns error? {
    Cricketers3[]|string result = check deepseekProvider->generate(`Name 10 world class cricketers as string`);
    test:assertTrue(result is Cricketers3[]);
}

@test:Config
function testGenerateMethodWithArrayUnionNull() returns error? {
    Cricketers4[]? result = check deepseekProvider->generate(`Name 10 world class cricketers`);
    test:assertTrue(result is Cricketers4[]);
}

@test:Config
function testGenerateMethodWithArrayUnionRecord() returns ai:Error? {
    Cricketers5[]|Cricketers6|error result = deepseekProvider->generate(`Name top 10 world class cricketers`);
    test:assertTrue(result is Cricketers5[]);
}

@test:Config
function testGenerateMethodWithArrayUnionRecord2() returns ai:Error? {
    Cricketers7[]|Cricketers8|error result = deepseekProvider->generate(`Name a random world class cricketer`);
    test:assertTrue(result is Cricketers8);
}

@test:Config
function testGenerateMethodWithTextChunk() returns error? {
    ai:TextChunk chunk = {
        content: string `Title: ${blog1.title} Content: ${blog1.content}`
    };
    ai:TextChunk[] chunks = [chunk, chunk];
    int maxScore = 10;

    int rating = check deepseekProvider->generate(`How would you rate this text chunk content out of ${maxScore}. ${chunk}.`);
    test:assertEquals(rating, 4);

    ReviewArray result = check deepseekProvider->generate(`How would you rate these text chunks out of ${maxScore}. ${chunks}. Thank you!`);
    Review r = check review.fromJsonStringWithType();
    test:assertEquals(result, [r, r]);
}

@test:Config
function testGenerateMethodInThinkingMode() returns error? {
    int rating = check deepseekThinkingProvider->generate(`Rate this blog out of 10.
        Title: ${blog1.title}
        Content: ${blog1.content}`);
    test:assertEquals(rating, 4);

    Review result = check deepseekThinkingProvider->generate(`Please rate this blog out of 10.
        Title: ${blog2.title}
        Content: ${blog2.content}`);
    test:assertEquals(result, check review.fromJsonStringWithType(Review));

    int[] ratings = check deepseekThinkingProvider->generate(`Evaluate this blogs out of 10.
        Title: ${blog1.title}
        Content: ${blog1.content}

        Title: ${blog1.title}
        Content: ${blog1.content}`);
    test:assertEquals(ratings, [9, 1]);
}

@test:Config
function testGenerateMethodWithInvalidTypeInThinkingMode() {
    boolean|error result = deepseekThinkingProvider->generate(`What is ${1} + ${1}?`);
    test:assertTrue(result is error);
    test:assertTrue((<error>result).message().includes(ERROR_MESSAGE));
}

@test:Config
function testChatWithDefaultConfigurations() returns error? {
    ai:ChatAssistantMessage response = check deepseekThinkingProvider->chat([{role: ai:USER, content: "Hello"}], []);
    string content = check response.content.ensureType();
    map<json> configurations = check content.fromJsonStringWithType();
    test:assertEquals(configurations["model"], DEEPSEEK_FLASH);
    test:assertEquals(configurations["max_tokens"], 4096);
    string[] keys = check configurations["keys"].cloneWithType();
    foreach string key in ["thinking", "reasoning_effort", "tool_choice", "response_format"] {
        test:assertTrue(keys.indexOf(key) is (), string `Unexpected '${key}' in the request`);
    }
}

@test:Config
function testChatWithCustomModelNameAndThinkingConfigurations() returns error? {
    ModelProvider provider = check new (API_KEY, "deepseek-v4-pro-0813", THINKING_SERVICE_URL, 8192,
        thinking = ENABLED, reasoningEffort = MAX);
    ai:ChatAssistantMessage response = check provider->chat([{role: ai:USER, content: "Hello"}], []);
    string content = check response.content.ensureType();
    map<json> configurations = check content.fromJsonStringWithType();
    test:assertEquals(configurations["model"], "deepseek-v4-pro-0813");
    test:assertEquals(configurations["max_tokens"], 8192);
    test:assertEquals(configurations["thinking"], {"type": "enabled"});
    test:assertEquals(configurations["reasoning_effort"], "max");
}

@test:Config
function testReasoningContentRoundTripInToolCallLoop() returns error? {
    ModelProvider provider = check new (API_KEY, DEEPSEEK_FLASH, THINKING_SERVICE_URL,
        thinking = ENABLED, reasoningEffort = HIGH);
    map<json> cityParameter = {"type": "object", "properties": {"city": {"type": "string"}}};
    ai:ChatCompletionFunctions[] tools = [
        {name: "getWeather", description: "Get the weather of a city", parameters: cityParameter},
        {name: "getTime", description: "Get the local time of a city", parameters: cityParameter}
    ];

    ai:ChatMessage[] history = [{role: ai:USER, content: WEATHER_QUERY}];
    ai:ChatAssistantMessage toolCallResponse = check provider->chat(history, tools);
    ai:FunctionCall[] toolCalls = check toolCallResponse.toolCalls.ensureType();
    test:assertEquals(toolCalls.map(toolCall => toolCall.id), ["call_weather", "call_time"]);

    // Add each tool call and its result as a separate pair, the same way the agent records them.
    foreach ai:FunctionCall toolCall in toolCalls {
        history.push({role: ai:ASSISTANT, toolCalls: [toolCall]},
            {role: "function", name: toolCall.name, content: "done", id: toolCall.id});
    }
    ai:ChatAssistantMessage answer = check provider->chat(history, tools);
    test:assertEquals(answer.content, WEATHER_ANSWER);

    history.push({role: ai:ASSISTANT, content: answer.content}, {role: ai:USER, content: "What about tomorrow?"});
    ai:ChatAssistantMessage forecast = check provider->chat(history, tools);
    test:assertEquals(forecast.content, FORECAST_ANSWER);
}

@test:Config
function testThinkingModeResolution() {
    test:assertTrue(isThinkingEnabled(DEEPSEEK_FLASH, (), ()));
    test:assertTrue(isThinkingEnabled(DEEPSEEK_V4_PRO, (), HIGH));
    test:assertTrue(isThinkingEnabled("deepseek-reasoner", (), ()));
    test:assertTrue(isThinkingEnabled("deepseek-chat", ENABLED, ()));
    test:assertFalse(isThinkingEnabled("deepseek-chat", (), ()));
    test:assertFalse(isThinkingEnabled(DEEPSEEK_FLASH, DISABLED, HIGH));
    test:assertFalse(isThinkingEnabled(DEEPSEEK_V4_PRO, (), NONE));
}
