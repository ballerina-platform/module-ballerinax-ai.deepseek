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

service /llm on new http:Listener(8080) {
    resource function post deepseek/chat/completions(
                DeepSeekChatCompletionRequest payload) returns DeepSeekChatCompletionResponse|error {
        test:assertEquals(payload.model, DEEPSEEK_V4_PRO);
        test:assertEquals(payload.max_tokens, DEFAULT_MAX_TOKEN_COUNT);
        test:assertEquals(payload.temperature, DEFAULT_TEMPERATURE);
        test:assertEquals(payload?.thinking, {'type: DISABLED});
        test:assertEquals(payload?.tool_choice, {'type: FUNCTION, 'function: {name: GET_RESULTS_TOOL}});
        test:assertEquals(payload?.response_format, ());
        DeepSeekChatRequestMessages[] messages = payload.messages;
        DeepseekChatUserMessage message = check messages[0].ensureType();

        string? content = message.content;
        if content is () {
            test:assertFail("Expected content in the payload");
        }

        test:assertEquals(content, getExpectedPrompt(content));
        test:assertEquals(message.role, "user");
        DeepseekTool[]? tools = payload.tools;
        if tools is () || tools.length() == 0 {
            test:assertFail("No tools in the payload");
        }

        map<json>? parameters = check tools[0].'function?.parameters.toJson().cloneWithType();
        if parameters is () {
            test:assertFail("No parameters in the expected tool");
        }

        test:assertEquals(parameters, getExpectedParameterSchema(content), string `Test failed for prompt:- ${content}`);
        return getTestServiceResponse(content);
    }

    resource function post thinking/chat/completions(map<json> payload) returns json|error {
        test:assertFalse(payload.hasKey("toolChoice"), "Tool choice should be sent as `tool_choice`");
        json[] messages = check payload["messages"].ensureType();
        map<json> firstMessage = check messages[0].ensureType();
        if payload.hasKey("response_format") {
            return getJsonOutputModeResponse(payload, messages);
        }
        if firstMessage["content"] == WEATHER_QUERY {
            return getToolLoopResponse(payload, messages);
        }
        // Echo the request configurations, so that the tests can verify them.
        json configurations = {
            model: payload["model"],
            max_tokens: payload["max_tokens"],
            thinking: payload["thinking"],
            reasoning_effort: payload["reasoning_effort"],
            keys: payload.keys()
        };
        return getMockChatResponse(configurations.toJsonString(), ());
    }
}
