/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <WebDriverAgentLib/XCElementSnapshot.h>
#import <WebDriverAgentLib/XCUIElement.h>

NS_ASSUME_NONNULL_BEGIN

@interface XCUIElement (FBUID)

/*! Represents unique internal element identifier, which is the same for an element and its snapshot */
@property (nonatomic, readonly, copy) NSString *fb_uid;

@end


@interface XCElementSnapshot (FBUID)

/*! Represents unique internal element identifier, which is the same for an element and its snapshot */
@property (nonatomic, readonly, copy) NSString *fb_uid;

@end

NS_ASSUME_NONNULL_END
