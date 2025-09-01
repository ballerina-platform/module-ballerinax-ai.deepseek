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
const RETRY_SERVICE_URL = "http://localhost:8080/llm/deepseek-retry";
const API_KEY = "not-a-real-api-key";
const ERROR_MESSAGE = "Error occurred while attempting to parse the response from the LLM as the expected type. Retrying and/or validating the prompt could fix the response.";
const RUNTIME_SCHEMA_NOT_SUPPORTED_ERROR_MESSAGE = "Runtime schema generation is not yet supported";

final ModelProvider deepseekProvider = check new (API_KEY, DEEPSEEK_CHAT, SERVICE_URL);

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
function testGenerateMethodWithInvalidRecordType() {
    ProductName[]|map<string>|error rating = deepseekProvider->generate(
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
function testGenerateWithValidRetryConfig() returns error? {
    final ModelProvider modelProvider =
        check new (API_KEY, DEEPSEEK_CHAT, RETRY_SERVICE_URL, generatorConfig = {retryConfig: {count: 2, interval: 2}});

    int|ai:Error rating = modelProvider->generate(`What is the result of ${1} + ${1}?`);
    test:assertEquals(rating, 2, "Failed with valid retry config {count: 2, interval: 2}");
}

@test:Config
function testGenerateWithDefaultRetryInterval() returns error? {
    final ModelProvider modelProvider =
        check new (API_KEY, DEEPSEEK_CHAT, RETRY_SERVICE_URL, generatorConfig = {retryConfig: {count: 2}});

    int|ai:Error rating = modelProvider->generate(`What is the result of 1 + 2?`);
    test:assertEquals(rating, 3, "Failed with retry config {count: 2}");
}

@test:Config
function testGenerateWithSingleRetry() returns error? {
    final ModelProvider modelProvider =
        check new (API_KEY, DEEPSEEK_CHAT, RETRY_SERVICE_URL, generatorConfig = {retryConfig: {count: 1}});

    int|ai:Error rating = modelProvider->generate(`What is the result of 1 + 3?`);
    test:assertEquals(rating, 4, "Failed with retry config {count: 1}");
}

@test:Config
function testGenerateWithEmptyRetryConfig() returns error? {
    final ModelProvider modelProvider =
        check new (API_KEY, DEEPSEEK_CHAT, RETRY_SERVICE_URL, generatorConfig = {retryConfig: {}});

    int|ai:Error rating = modelProvider->generate(`What is the result of 1 + 4?`);
    test:assertEquals(rating, 5, "Failed with empty retry config {}");
}

@test:Config
function testGenerateFailsWithInvalidNegativeRetryCount() returns error? {
    final ModelProvider modelProvider =
        check new (API_KEY, DEEPSEEK_CHAT, RETRY_SERVICE_URL, generatorConfig = {retryConfig: {count: -1}});

    int|ai:Error rating = modelProvider->generate(`What is the result of ${1} + ${6}?`);
    test:assertTrue(rating is error, "Expected an error for negative retry count");
    if rating is error {
        test:assertEquals(rating.message(), "Invalid retry count: -1");
    }
}

@test:Config
function testGenerateFailsWithInvalidNegativeRetryInterval() returns error? {
    final ModelProvider modelProvider =
        check new (API_KEY, DEEPSEEK_CHAT, RETRY_SERVICE_URL, generatorConfig = {retryConfig: {count: 4, interval: -1}});

    int|ai:Error rating = modelProvider->generate(`What is the result of ${1} + ${6}?`);
    test:assertTrue(rating is error, "Expected an error for negative retry interval");
    if rating is error {
        test:assertEquals(rating.message(), "Invalid retry interval: -1");
    }
}
