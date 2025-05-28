## Overview

This module offers APIs for connecting with Deepseek Large Language Models (LLM).

## Prerequisites

Before using this module in your Ballerina application, first you must obtain the nessary configuration to engage the LLM.



## Quickstart

To use the `ai.model.provider.deepseek` module in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `ai.model.provider.deepseek;` module.

```ballerina
import ballerinax/ai.model.provider.deepseek;
```

### Step 2: Intialize the Model Provider

Here's how to initialize the Model Provider:

```ballerina
import ballerina/ai;
import ballerinax/ai.model.provider.deepseek;

final ai:ModelProvider deepseekModel = check new deepseek:Provider("deepseekApiKey");
```

### Step 4: Invoke chat completion

```
ai:ChatMessage[] chatMessages = [{role: "user", content: "hi"}];
ai:ChatAssistantMessage response = check deepseekModel->chat(chatMessages, tools = []);

chatMessages.push(response);
```
