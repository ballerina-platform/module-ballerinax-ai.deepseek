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

import ballerina/http;
import ballerina/test;

// Mock Server-Sent Events endpoints backing the streaming tests.
//
// Each scenario gets its own base path so a test can point a provider at exactly the stream
// it wants to exercise: a provider built with `serviceUrl` `.../sse/<scenario>` posts to
// `<scenario>/chat/completions` under this service.
service /sse on new http:Listener(8081) {

    // Plain text answer, ending with a finish-reason chunk and a usage-only chunk.
    resource function post text/chat/completions(@http:Payload json payload)
            returns stream<http:SseEvent, error?>|error {
        test:assertEquals(check payload.'stream, true, "Streaming requests must set 'stream'");
        test:assertEquals(check payload.stream_options.include_usage, true,
                "Streaming requests must ask for usage on the final chunk");
        return sseEvents([
            chatChunk(string `{"role":"assistant","content":"Hello"}`),
            // `system_fingerprint` is explicitly null on some endpoints; the chunk must still bind.
            string `{"id":"chat-1","object":"chat.completion.chunk","created":1,` +
                string `"model":"deepseek-chat","system_fingerprint":null,"choices":` +
                string `[{"index":0,"delta":{"content":" world"},"finish_reason":null}]}`,
            chatChunkWithFinishReason("stop"),
            string `{"id":"chat-1","object":"chat.completion.chunk","created":1,` +
                string `"model":"deepseek-chat","choices":[],` +
                string `"usage":{"prompt_tokens":10,"completion_tokens":5,"total_tokens":15}}`,
            "[DONE]"
        ]);
    }

    // Frames carrying only `choices` - no `id`, `object`, `created`, `model` or
    // `system_fingerprint`. `serviceUrl` is configurable, so the stream can come from an
    // OpenAI-compatible endpoint that sends a leaner envelope than DeepSeek's own.
    resource function post minimal/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            string `{"choices":[{"index":0,"delta":{"role":"assistant","content":"Lean"}}]}`,
            string `{"choices":[{"index":0,"delta":{"content":" envelope"},"finish_reason":"stop"}]}`,
            "[DONE]"
        ]);
    }

    // Two tool calls streamed in fragments, ending with a `tool_calls` finish reason.
    resource function post tools/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            chatChunk(string `{"role":"assistant","tool_calls":[{"index":0,"id":"call_a",` +
                    string `"type":"function","function":{"name":"getWeather","arguments":""}}]}`),
            chatChunk(string `{"tool_calls":[{"index":0,"function":{"arguments":"{\"city\":"}}]}`),
            chatChunk(string `{"tool_calls":[{"index":1,"id":"call_b","type":"function",` +
                    string `"function":{"name":"getTime","arguments":"{}"}}]}`),
            chatChunk(string `{"tool_calls":[{"index":0,"function":{"arguments":"\"Colombo\"}"}}]}`),
            chatChunkWithFinishReason("tool_calls"),
            "[DONE]"
        ]);
    }

    // `deepseek-reasoner` streams its chain-of-thought as `reasoning_content` before the answer.
    resource function post reasoning/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            chatChunk(string `{"role":"assistant","reasoning_content":"Let me think"}`),
            chatChunk(string `{"reasoning_content":" about it"}`),
            chatChunk(string `{"content":"42"}`),
            chatChunkWithFinishReason("stop"),
            "[DONE]"
        ]);
    }

    // A finish reason outside the normalized set; DeepSeek emits this one when it runs out
    // of capacity part-way through a generation.
    resource function post unknownfinish/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            chatChunk(string `{"role":"assistant","content":"Partial"}`),
            chatChunkWithFinishReason("insufficient_system_resource"),
            "[DONE]"
        ]);
    }

    // A generation cut short part-way: content, then the error frame DeepSeek emits in place
    // of the rest of the answer.
    resource function post midstreamerror/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            chatChunk(string `{"role":"assistant","content":"Partial"}`),
            string `{"error":{"message":"Rate limit reached","type":"rate_limit_error"}}`
        ]);
    }

    // A frame that is not JSON at all.
    resource function post malformed/chat/completions() returns stream<http:SseEvent, error?>|error {
        return sseEvents([
            chatChunk(string `{"role":"assistant","content":"Partial"}`),
            "{not json at all"
        ]);
    }

    // A rejected request: the endpoint answers with a normal JSON error body, not a stream.
    resource function post unauthorized/chat/completions() returns http:Response {
        return errorResponse(http:STATUS_UNAUTHORIZED, "Authentication Fails, Your api key is invalid");
    }

    // DeepSeek answers 402 when the account has run out of credit - the failure a caller is
    // most likely to hit in practice, and the one a bare "could not open the stream" hides.
    resource function post insufficientbalance/chat/completions() returns http:Response {
        return errorResponse(http:STATUS_PAYMENT_REQUIRED, "Insufficient Balance");
    }
}

# Wraps each payload as the `data` of one Server-Sent Event.
#
# + payloads - The `data` payloads to emit, in order
# + return - The event stream the mock endpoint answers with
isolated function sseEvents(string[] payloads) returns stream<http:SseEvent, error?> {
    http:SseEvent[] events = from string payload in payloads
        select {data: payload};
    return events.toStream();
}

# Builds one `chat.completion.chunk` frame around the given delta.
#
# + delta - The `delta` object as a JSON string
# + return - The frame's `data` payload
isolated function chatChunk(string delta) returns string =>
    string `{"id":"chat-1","object":"chat.completion.chunk","created":1,"model":"deepseek-chat",` +
        string `"system_fingerprint":"fp_test","choices":[{"index":0,"delta":${delta},"finish_reason":null}]}`;

# Builds the terminal `chat.completion.chunk` frame carrying a finish reason.
#
# + finishReason - The wire finish reason
# + return - The frame's `data` payload
isolated function chatChunkWithFinishReason(string finishReason) returns string =>
    string `{"id":"chat-1","object":"chat.completion.chunk","created":1,"model":"deepseek-chat",` +
        string `"system_fingerprint":"fp_test","choices":[{"index":0,"delta":{},"finish_reason":"${finishReason}"}]}`;

# The JSON error body DeepSeek answers a rejected request with.
#
# + statusCode - The HTTP status to answer with
# + message - The failure detail carried in the error envelope
# + return - The error response
isolated function errorResponse(int statusCode, string message) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setJsonPayload({'error: {message, 'type: "invalid_request_error"}});
    return response;
}
