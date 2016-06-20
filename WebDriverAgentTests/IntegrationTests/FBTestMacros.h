/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/FBRunLoopSpinner.h>

/**
 Macro used to wait till certain condition is true.
 If condition will not become true within default timeout (1m) it will fail running test
 */
#define FBAssertWaitTillBecomesTrue(condition) \
  ({ \
    NSError *error; \
    XCTAssertTrue([[[FBRunLoopSpinner new] \
      interval:1.0] \
    spinUntilTrue:^BOOL{ \
      return (condition); \
    }]); \
    XCTAssertNil(error); \
  })
