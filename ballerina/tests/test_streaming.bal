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
import ballerina/test;

const STREAM_SERVICE_URL = "http://localhost:8081/sse";

isolated function streamProvider(string scenario) returns ModelProvider|ai:Error =>
    new (API_KEY, DEEPSEEK_CHAT, string `${STREAM_SERVICE_URL}/${scenario}`);

// Drains a chunk stream into a list, so a test can assert over the whole sequence.
isolated function collectChunks(stream<ai:ChatCompletionChunk, ai:Error?> chunks)
        returns ai:ChatCompletionChunk[]|ai:Error {
    ai:ChatCompletionChunk[] collected = [];
    while true {
        record {|ai:ChatCompletionChunk value;|}|ai:Error? next = chunks.next();
        if next is () {
            return collected;
        }
        if next is ai:Error {
            return next;
        }
        collected.push(next.value);
    }
}

// Concatenates every text fragment in a chunk sequence.
isolated function joinContent(ai:ChatCompletionChunk[] chunks) returns string {
    string text = "";
    foreach ai:ChatCompletionChunk chunk in chunks {
        foreach ai:ChatCompletionChunkChoice choice in chunk.choices {
            string? content = choice.delta.content;
            if content is string {
                text += content;
            }
        }
    }
    return text;
}

// Concatenates every reasoning fragment in a chunk sequence.
isolated function joinReasoning(ai:ChatCompletionChunk[] chunks) returns string {
    string reasoning = "";
    foreach ai:ChatCompletionChunk chunk in chunks {
        foreach ai:ChatCompletionChunkChoice choice in chunk.choices {
            string? fragment = choice.delta.reasoning;
            if fragment is string {
                reasoning += fragment;
            }
        }
    }
    return reasoning;
}

// The finish reason of the one chunk that carries it, or `()` when none does.
isolated function finishReasonOf(ai:ChatCompletionChunk[] chunks) returns ai:FinishReason? {
    foreach ai:ChatCompletionChunk chunk in chunks {
        foreach ai:ChatCompletionChunkChoice choice in chunk.choices {
            ai:FinishReason? finishReason = choice.finishReason;
            if finishReason is ai:FinishReason {
                return finishReason;
            }
        }
    }
    return ();
}

@test:Config
function testChatStreamCollectsTextFragments() returns error? {
    ModelProvider model = check streamProvider("text");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream =
        check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertEquals(joinContent(chunks), "Hello world");
    test:assertEquals(finishReasonOf(chunks), ai:STOP);
    test:assertEquals(chunks[0].choices[0].delta.role, ai:ASSISTANT);
    test:assertEquals(chunks[0].id, "chat-1");
    test:assertEquals(chunks[0].model, "deepseek-chat");
}

@test:Config
function testChatStreamReportsUsageOnFinalChunk() returns error? {
    ModelProvider model = check streamProvider("text");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream =
        check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    ai:CompletionTokenUsage? usage = chunks[chunks.length() - 1]?.usage;
    if usage is () {
        test:assertFail("Expected usage on the final chunk");
    }
    test:assertEquals(usage.promptTokens, 10);
    test:assertEquals(usage.completionTokens, 5);
    test:assertEquals(usage.totalTokens, 15);
}

@test:Config
function testChatStreamBindsChunksWithoutEnvelopeFields() returns error? {
    // A chunk type that required `id`, `object`, `created`, `model` or `system_fingerprint`
    // would fail to bind here, and the skip-on-failure path would hand the caller an empty
    // stream that looks successful.
    ModelProvider model = check streamProvider("minimal");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream =
        check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertEquals(joinContent(chunks), "Lean envelope");
    test:assertEquals(finishReasonOf(chunks), ai:STOP);
}

@test:Config
function testChatStreamForwardsToolCallFragments() returns error? {
    ModelProvider model = check streamProvider("tools");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream =
        check model->chatStream({role: ai:USER, content: "Weather and time?"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    // Fragments must be forwarded on every chunk, not just the first, and stay correlated
    // by `index` so the caller can accumulate the arguments of each call.
    map<string> argumentsByIndex = {};
    map<string> namesByIndex = {};
    map<string> idsByIndex = {};
    foreach ai:ChatCompletionChunk chunk in chunks {
        foreach ai:ChatCompletionChunkChoice choice in chunk.choices {
            ai:ToolCallChunk[]? toolCalls = choice.delta.toolCalls;
            if toolCalls is () {
                continue;
            }
            foreach ai:ToolCallChunk toolCall in toolCalls {
                string key = toolCall.index.toString();
                string? id = toolCall?.id;
                if id is string {
                    idsByIndex[key] = id;
                }
                ai:FunctionCallChunk? 'function = toolCall?.'function;
                if 'function is () {
                    continue;
                }
                string? name = 'function?.name;
                if name is string {
                    namesByIndex[key] = name;
                }
                string? arguments = 'function?.arguments;
                if arguments is string {
                    argumentsByIndex[key] = (argumentsByIndex[key] ?: "") + arguments;
                }
            }
        }
    }

    test:assertEquals(idsByIndex, {"0": "call_a", "1": "call_b"});
    test:assertEquals(namesByIndex, {"0": "getWeather", "1": "getTime"});
    test:assertEquals(argumentsByIndex, {"0": string `{"city":"Colombo"}`, "1": "{}"});
    test:assertEquals(finishReasonOf(chunks), ai:TOOL_CALLS);
}

@test:Config
function testChatStreamMapsReasoningContent() returns error? {
    ModelProvider model = check streamProvider("reasoning");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream =
        check model->chatStream({role: ai:USER, content: "What is 6 times 7?"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertEquals(joinReasoning(chunks), "Let me think about it");
    test:assertEquals(joinContent(chunks), "42");
}

@test:Config
function testChatStreamMapsUnknownFinishReasonToNil() returns error? {
    // DeepSeek's `insufficient_system_resource` has no `ai:FinishReason` counterpart; it must
    // map to `()` rather than panic on a cast.
    ModelProvider model = check streamProvider("unknownfinish");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream =
        check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[] chunks = check collectChunks(chunkStream);

    test:assertEquals(joinContent(chunks), "Partial");
    test:assertEquals(finishReasonOf(chunks), ());
}

@test:Config
function testChatStreamSurfacesMidStreamError() returns error? {
    // Skipping the error frame would end the stream silently, handing the caller a truncated
    // answer that looks complete.
    ModelProvider model = check streamProvider("midstreamerror");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream =
        check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[]|ai:Error result = collectChunks(chunkStream);

    if result is ai:ChatCompletionChunk[] {
        test:assertFail("Expected the mid-stream error frame to fail the stream");
    }
    test:assertTrue(result.message().includes("Rate limit reached"),
            string `Expected the model's own message: ${result.message()}`);
}

@test:Config
function testChatStreamSurfacesMalformedFrame() returns error? {
    ModelProvider model = check streamProvider("malformed");
    stream<ai:ChatCompletionChunk, ai:Error?> chunkStream =
        check model->chatStream({role: ai:USER, content: "Say hello"});
    ai:ChatCompletionChunk[]|ai:Error result = collectChunks(chunkStream);

    if result is ai:ChatCompletionChunk[] {
        test:assertFail("Expected an unparseable frame to fail the stream");
    }
    test:assertTrue(result is ai:LlmInvalidResponseError,
            string `Expected an invalid-response error: ${result.message()}`);
}

@test:Config
function testChatStreamSurfacesHttpErrorStatus() returns error? {
    ModelProvider model = check streamProvider("unauthorized");
    stream<ai:ChatCompletionChunk, ai:Error?>|ai:Error result =
        model->chatStream({role: ai:USER, content: "Say hello"});

    if result !is ai:Error {
        test:assertFail("Expected a 401 to fail before the stream opens");
    }
    // The caller needs DeepSeek's own message, not just "the stream could not be opened".
    test:assertTrue(result.message().includes("401"), string `Expected the status: ${result.message()}`);
    test:assertTrue(result.message().includes("Authentication Fails"),
            string `Expected the API error message: ${result.message()}`);
}

@test:Config
function testChatStreamSurfacesInsufficientBalance() returns error? {
    ModelProvider model = check streamProvider("insufficientbalance");
    stream<ai:ChatCompletionChunk, ai:Error?>|ai:Error result =
        model->chatStream({role: ai:USER, content: "Say hello"});

    if result !is ai:Error {
        test:assertFail("Expected a 402 to fail before the stream opens");
    }
    test:assertTrue(result.message().includes("Insufficient Balance"),
            string `Expected the API error message: ${result.message()}`);
}

@test:Config
function testGenerateStreamProjectsTextFragments() returns error? {
    ModelProvider model = check streamProvider("text");
    stream<string, ai:Error?> fragments = check model->generateStream(`Say hello`);
    string text = "";
    check from string fragment in fragments
        do {
            text += fragment;
        };
    test:assertEquals(text, "Hello world");
}

@test:Config
function testGenerateStreamDropsReasoningFragments() returns error? {
    // Only the answer text is streamed; the chain-of-thought is not a partial answer.
    ModelProvider model = check streamProvider("reasoning");
    stream<string, ai:Error?> fragments = check model->generateStream(`What is 6 times 7?`);
    string text = "";
    check from string fragment in fragments
        do {
            text += fragment;
        };
    test:assertEquals(text, "42");
}

@test:Config
function testGenerateStreamRejectsNonStringTypes() returns error? {
    ModelProvider model = check streamProvider("text");
    stream<int, ai:Error?>|ai:Error result = model->generateStream(`Rate this out of 10`);

    if result !is ai:Error {
        test:assertFail("Only 'string' can be streamed");
    }
    test:assertTrue(result.message().includes("supports only 'string'"),
            string `Unexpected error message: ${result.message()}`);
}
