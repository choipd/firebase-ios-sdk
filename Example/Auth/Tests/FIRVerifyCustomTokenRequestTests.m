/*
 * Copyright 2017 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <XCTest/XCTest.h>

#import "FIRAuthErrors.h"
#import "FIRAuthBackend.h"
#import "FIRGetOOBConfirmationCodeResponse.h"
#import "FIRVerifyCustomTokenRequest.h"
#import "FIRVerifyCustomTokenResponse.h"
#import "FIRFakeBackendRPCIssuer.h"

/** @var kTestAPIKey
    @brief Fake API key used for testing.
 */
static NSString *const kTestAPIKey = @"APIKey";

/** @var kTestTokenKey
    @brief The name of the "token" property in the response.
 */
static NSString *const kTestTokenKey = @"token";

/** @var kTestToken
    @brief testing token.
 */
static NSString *const kTestToken = @"test token";

/** @var kReturnSecureTokenKey
    @brief The key for the "returnSecureToken" value in the request.
 */
static NSString *const kReturnSecureTokenKey = @"returnSecureToken";

/** @var kExpectedAPIURL
    @brief The expected URL for test calls.
 */
static NSString *const kExpectedAPIURL =
    @"https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyCustomToken?key=APIKey";

@interface FIRVerifyCustomTokenRequestTests : XCTestCase
@end
@implementation FIRVerifyCustomTokenRequestTests {
  /** @var _RPCIssuer
      @brief This backend RPC issuer is used to fake network responses for each test in the suite.
          In the @c setUp method we initialize this and set @c FIRAuthBackend's RPC issuer to it.
   */
  FIRFakeBackendRPCIssuer *_RPCIssuer;
}

- (void)setUp {
  [super setUp];
  FIRFakeBackendRPCIssuer *RPCIssuer = [[FIRFakeBackendRPCIssuer alloc] init];
  [FIRAuthBackend setDefaultBackendImplementationWithRPCIssuer:RPCIssuer];
  _RPCIssuer = RPCIssuer;
}

- (void)tearDown {
  _RPCIssuer = nil;
  [FIRAuthBackend setDefaultBackendImplementationWithRPCIssuer:nil];
  [super tearDown];
}

/** @fn testVerifyCustomTokenRequest
    @brief Tests the verify custom token request.
 */
- (void)testVerifyCustomTokenRequest {
  FIRVerifyCustomTokenRequest *request =
      [[FIRVerifyCustomTokenRequest alloc] initWithToken:kTestToken APIKey:kTestAPIKey];
  request.returnSecureToken = NO;
  [FIRAuthBackend verifyCustomToken:request
                           callback:^(FIRVerifyCustomTokenResponse *_Nullable response,
                                           NSError *_Nullable error) {
  }];

  XCTAssertEqualObjects(_RPCIssuer.requestURL.absoluteString, kExpectedAPIURL);
  XCTAssertNotNil(_RPCIssuer.decodedRequest);
  XCTAssertNotNil(_RPCIssuer.decodedRequest[kTestTokenKey]);
  XCTAssertNil(_RPCIssuer.decodedRequest[kReturnSecureTokenKey]);
}

/** @fn testVerifyCustomTokenRequestOptionalFields
    @brief Tests the verify custom token request with optional fields.
 */
- (void)testVerifyCustomTokenRequestOptionalFields {
  FIRVerifyCustomTokenRequest *request =
      [[FIRVerifyCustomTokenRequest alloc] initWithToken:kTestToken APIKey:kTestAPIKey];
  [FIRAuthBackend verifyCustomToken:request
                           callback:^(FIRVerifyCustomTokenResponse *_Nullable response,
                                           NSError *_Nullable error) {
  }];

  XCTAssertEqualObjects(_RPCIssuer.requestURL.absoluteString, kExpectedAPIURL);
  XCTAssertNotNil(_RPCIssuer.decodedRequest);
  XCTAssertNotNil(_RPCIssuer.decodedRequest[kTestTokenKey]);
  XCTAssertTrue([_RPCIssuer.decodedRequest[kReturnSecureTokenKey] boolValue]);
}

@end
