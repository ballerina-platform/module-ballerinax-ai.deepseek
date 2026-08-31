## Overview

DeepSeek provides high-performance large language models (LLMs) optimized for various natural language processing tasks.

The DeepSeek connector offers APIs for connecting with DeepSeek Large Language Models (LLMs), enabling the integration of advanced conversational AI and language processing capabilities into applications.

### Key Features

- Connect and interact with DeepSeek Large Language Models (LLMs)
- Support for DeepSeek-V3, DeepSeek-Coder, and other models
- Efficient handling of conversational prompts and completions
- Secure communication with API key authentication
- Streaming responses, so the answer can be shown as it is produced

## Prerequisites

Before using this module in your Ballerina application, first you must obtain the necessary configuration to engage the LLM.



## Quickstart

To use the `ai.deepseek` module in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `ai.deepseek;` module.

```ballerina
import ballerinax/ai.deepseek;
```

### Step 2: Initialize the Model Provider

Here's how to initialize the Model Provider:

```ballerina
import ballerina/ai;
import ballerinax/ai.deepseek;

final ai:ModelProvider deepseekModel = check new deepseek:ModelProvider("deepseekApiKey");
```

### Step 3: Invoke chat completion

```ballerina
ai:ChatMessage[] chatMessages = [{role: "user", content: "hi"}];
ai:ChatAssistantMessage response = check deepseekModel->chat(chatMessages, tools = []);

chatMessages.push(response);
```

### Step 4: Stream the response

To show the answer as it is produced rather than waiting for all of it, use `generateStream` for
the generated text, or `chatStream` for the raw chunks:

```ballerina
stream<string, ai:Error?> fragments = check deepseekModel->generateStream(`Tell me about Ballerina`);
check from string fragment in fragments
    do {
        io:print(fragment);
    };
```

Each `ai:ChatCompletionChunk` from `chatStream` carries text, reasoning and tool-call fragments,
and the last one carries the finish reason and the token usage. Tool-call fragments are correlated
by `index`, so a caller accumulates the arguments of each call across chunks.

`generateStream` supports only `string`, since a partial generation is a valid value only for
`string`; use `generate` for structured output. It also streams the answer text only - on
`deepseek-reasoner`, the chain-of-thought that precedes the answer is dropped. To observe it, use
`chatStream` and read `delta.reasoning`:

```ballerina
final ai:ModelProvider reasoner = check new deepseek:ModelProvider("deepseekApiKey", deepseek:DEEPSEEK_REASONER);
stream<ai:ChatCompletionChunk, ai:Error?> chunks =
    check reasoner->chatStream({role: ai:USER, content: "What is 6 times 7?"});
check from ai:ChatCompletionChunk chunk in chunks
    do {
        foreach ai:ChatCompletionChunkChoice choice in chunk.choices {
            io:print(choice.delta.reasoning ?: choice.delta.content ?: "");
        }
    };
```
