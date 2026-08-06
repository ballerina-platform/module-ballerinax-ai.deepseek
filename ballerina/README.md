## Overview

The `ai.deepseek` module provides a DeepSeek-backed `ModelProvider` implementation for the [`ballerina/ai`](https://central.ballerina.io/ballerina/ai/latest) agent framework. Use it to drive DeepSeek models (DeepSeek-V3, DeepSeek-Coder, and others) from Ballerina AI agents and other `ai`-module abstractions, rather than calling the DeepSeek REST API directly.

### Key Features

- Connect and interact with DeepSeek Large Language Models (LLMs)
- Support for DeepSeek-V3, DeepSeek-Coder, and other models
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

### Step 4: Invoke chat completion

```ballerina
ai:ChatMessage[] chatMessages = [{role: "user", content: "hi"}];
ai:ChatAssistantMessage response = check deepseekModel->chat(chatMessages, tools = []);

chatMessages.push(response);
```
