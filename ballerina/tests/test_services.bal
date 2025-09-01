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

import ballerina/http;
import ballerina/test;

isolated service /llm on new http:Listener(8080) {
    private map<int> retryCountMap = {};

    isolated resource function post deepseek/chat/completions(
                @http:Payload json payload) returns DeepSeekChatCompletionResponse|error {
        
        [json[], string] [_, initialContent] = check validateDeepseekChatPayload(payload);
        return getTestServiceResponse(initialContent);
    }

    isolated resource function post deepseek\-retry/chat/completions(
            @http:Payload json payload) returns DeepSeekChatCompletionResponse|error {
        
        [json[], string] [messages, initialContent] = 
            check validateDeepseekChatPayload(payload);

        int index;
        lock {
            index = updateRetryCountMap(initialContent, self.retryCountMap);
        }

        check assertDeepseekMessages(messages, initialContent, index);
        return check getTestServiceResponse(initialContent, index);
    }
}

isolated function validateDeepseekChatPayload(json payload) 
        returns [json[], string]|error {
    
    test:assertEquals(payload.model, DEEPSEEK_CHAT);
    test:assertEquals(payload.max_tokens, DEFAULT_MAX_TOKEN_COUNT);
    test:assertEquals(payload.temperature, DEFAULT_TEMPERATURE);

    json[] messages = check payload.messages.ensureType();
    if messages.length() == 0 {
        test:assertFail("Expected at least one message in the payload");
    }

    json firstMessage = messages[0];
    test:assertEquals(firstMessage.role, "user");

    string? initialContent = check firstMessage.content;
    if initialContent is () {
        test:assertFail("Expected content in the initial message");
    }

    json[]? tools = check payload.tools.ensureType();
    if tools is () || tools.length() == 0 {
        test:assertFail("No tools in the payload");
    }

    map<json>? parameters = check ((check tools[0].'function?.parameters).toJson()).cloneWithType();
    if parameters is () {
        test:assertFail("No parameters in the expected tool");
    }

    test:assertEquals(parameters, getExpectedParameterSchema(initialContent),
            string `Parameter assertion failed for prompt: '${initialContent}'`);

    return [messages, initialContent];
}

isolated function assertDeepseekMessages(json[] messages, 
        string initialContent, int index) returns error? {

    int userMessageIndex = index * 2;
    if userMessageIndex >= messages.length() {
        test:assertFail(string `Expected at least ${userMessageIndex + 1} message(s) for retry index ${index}`);
    }

    json userMessage = check messages[userMessageIndex].ensureType();
    string? content = check userMessage.content;

    if index == 0 {
        test:assertEquals(content, getExpectedPrompt(initialContent),
            string `Prompt assertion failed for initial call with prompt: '${initialContent}'`);
        return;
    }

    if index == 1 {
        test:assertEquals(content, check getExpectedPromptForFirstRetryCall(initialContent),
            string `Prompt assertion failed for the first retry attempt with prompt: '${initialContent}'`);
        return;
    }

    test:assertEquals(content, check getExpectedPromptForSecondRetryCall(initialContent),
            string `Prompt assertion failed for the second retry attempt with prompt: '${initialContent}'`);
}

isolated function updateRetryCountMap(string initialText, map<int> retryCountMap) returns int {
    if retryCountMap.hasKey(initialText) {
        int index = retryCountMap.get(initialText) + 1;
        retryCountMap[initialText] = index;
        return index;
    }

    retryCountMap[initialText] = 0;
    return 0;
}
