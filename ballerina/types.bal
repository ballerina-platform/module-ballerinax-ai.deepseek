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

public enum DEEPSEEK_MODEL_NAMES {
    DEEPSEEK_CHAT = "deepseek-chat",
    DEEPSEEK_REASONER = "deepseek-reasoner"
}

# Configurations for controlling the behaviours when communicating with a remote HTTP endpoint.
@display {label: "Connection Configuration"}
public type ConnectionConfig record {|

    # The HTTP version understood by the client
    @display {label: "HTTP Version"}
    http:HttpVersion httpVersion = http:HTTP_2_0;

    # Configurations related to HTTP/1.x protocol
    @display {label: "HTTP1 Settings"}
    http:ClientHttp1Settings http1Settings?;

    # Configurations related to HTTP/2 protocol
    @display {label: "HTTP2 Settings"}
    http:ClientHttp2Settings http2Settings?;

    # The maximum time to wait (in seconds) for a response before closing the connection
    @display {label: "Timeout"}
    decimal timeout = 60;

    # The choice of setting `forwarded`/`x-forwarded` header
    @display {label: "Forwarded"}
    string forwarded = "disable";

    # Configurations associated with request pooling
    @display {label: "Pool Configuration"}
    http:PoolConfiguration poolConfig?;

    # HTTP caching related configurations
    @display {label: "Cache Configuration"}
    http:CacheConfig cache?;

    # Specifies the way of handling compression (`accept-encoding`) header
    @display {label: "Compression"}
    http:Compression compression = http:COMPRESSION_AUTO;

    # Configurations associated with the behaviour of the Circuit Breaker
    @display {label: "Circuit Breaker Configuration"}
    http:CircuitBreakerConfig circuitBreaker?;

    # Configurations associated with retrying
    @display {label: "Retry Configuration"}
    http:RetryConfig retryConfig?;

    # Configurations associated with inbound response size limits
    @display {label: "Response Limit Configuration"}
    http:ResponseLimitConfigs responseLimits?;

    # SSL/TLS-related options
    @display {label: "Secure Socket Configuration"}
    http:ClientSecureSocket secureSocket?;

    # Proxy server related options
    @display {label: "Proxy Configuration"}
    http:ProxyConfig proxy?;

    # Enables the inbound payload validation functionality which provided by the constraint package. Enabled by default
    @display {label: "Payload Validation"}
    boolean validation = true;
|};

public type DeepseekChatResponseFunction record {
    string name;
    string arguments;
};

type DeepseekChatResponseToolCall record {
    string id;
    string 'type;
    DeepseekChatResponseFunction 'function;
};

type DeepseekChatResponseMessage record {
    string role;
    string? content = ();
    DeepseekChatResponseToolCall[]? tool_calls = ();
};

type DeepseekChatResponseChoice record {
    DeepseekChatResponseMessage message;
};

type DeepSeekChatCompletionResponse record {
    string id;
    DeepseekChatResponseChoice[] choices;
};

type DeepseekChatSystemMessage record {|
    string content;
    string role = ai:SYSTEM;
|};

type DeepseekChatAssistantMessage record {
    string? content = ();
    string role = "assistant";
    DeepseekChatResponseToolCall[]? tool_calls = ();
};

const TOOL_ROLE = "tool";

type DeepseekChatToolMessage record {|
    string content;
    string role = TOOL_ROLE;
    string tool_call_id;
|};

type DeepseekChatUserMessage record {|
    string content;
    string role = ai:USER;
|};

type DeepSeekChatRequestMessages DeepseekChatSystemMessage|DeepseekChatUserMessage
    |DeepseekChatAssistantMessage|DeepseekChatToolMessage;

type DeepseekFunction record {|
    string name;
    string description;
    map<json> parameters?;
|};

type DeepseekTool record {|
    string 'type = ai:FUNCTION;
    DeepseekFunction 'function;
|};

type DeepSeekToolChoice record {|
    FUNCTION 'type?;
    record {|
        string name;
    |} 'function?;
|};

type DeepSeekChatCompletionRequest record {|
    DeepSeekChatRequestMessages[] messages;
    DEEPSEEK_MODEL_NAMES model;
    int? max_tokens;
    string?|string[]? stop = ();
    int? temperature = 1;
    DeepseekTool[]? tools = ();
    DeepSeekToolChoice? toolChoice = ();
|};
