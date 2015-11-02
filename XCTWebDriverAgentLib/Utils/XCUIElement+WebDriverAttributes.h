/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <XCElementSnapshot.h>

#import <XCTWebDriverAgentLib/XCUIElement.h>


NSString *xctAttributeNameForWDAttributeName(NSString *wdName);


@protocol WebDriverAttributes <NSObject>
@property (atomic, copy, readonly) NSString *wdName;
@property (atomic, copy, readonly) NSString *wdLabel;
@property (atomic, copy, readonly) NSString *wdType;
@property (atomic, copy, readonly) NSDictionary *wdRect;
@property (atomic, readonly) id wdValue;

- (id)valueForWDAttributeName:(NSString *)name;

@end

@interface XCUIElement (WebDriverAttributes) <WebDriverAttributes>

@end


@interface XCElementSnapshot (WebDriverAttributes) <WebDriverAttributes>

@end
