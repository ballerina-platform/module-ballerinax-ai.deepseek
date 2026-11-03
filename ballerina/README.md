## Overview

DeepSeek provides high-performance large language models (LLMs) optimized for various natural language processing tasks.

The DeepSeek connector offers APIs for connecting with DeepSeek Large Language Models (LLMs), enabling the integration of advanced conversational AI and language processing capabilities into applications.

### Key Features

- Connect and interact with DeepSeek Large Language Models (LLMs)
- Support for the DeepSeek V4 models (`deepseek-flash` and `deepseek-v4-pro`)
- Control over the thinking mode and the reasoning effort
- Efficient handling of conversational prompts and completions
- Secure communication with API key authentication

## Prerequisites

Before using this module in your Ballerina application, first you must obtain the nessary configuration to engage the LLM.



## Quickstart

To use the `ai.deepseek` module in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `ai.deepseek;` module.

```ballerina
import ballerinax/ai.deepseek;
```

### Step 2: Intialize the Model Provider

Here's how to initialize the Model Provider:

```ballerina
import ballerina/ai;
import ballerinax/ai.deepseek;

final ai:ModelProvider deepseekModel = check new deepseek:ModelProvider("deepseekApiKey");
```

The provider uses the `deepseek-flash` model by default. A different model, the thinking mode and the reasoning effort can be configured as follows:

```ballerina
final ai:ModelProvider deepseekModel = check new deepseek:ModelProvider("deepseekApiKey", deepseek:DEEPSEEK_V4_PRO,
    thinking = deepseek:ENABLED, reasoningEffort = deepseek:HIGH);
```

> **Note:** The `deepseek-chat` and `deepseek-reasoner` models are deprecated, as DeepSeek discontinued these model names on July 24, 2026. Use `deepseek-flash` with `thinking` set to `deepseek:DISABLED` in place of `deepseek-chat`, and `deepseek-flash` in place of `deepseek-reasoner`.

### Step 4: Invoke chat completion

```ballerina
ai:ChatMessage[] chatMessages = [{role: "user", content: "hi"}];
ai:ChatAssistantMessage response = check deepseekModel->chat(chatMessages, tools = []);

chatMessages.push(response);
```
