// Copyright 2004-present Facebook. All Rights Reserved.

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

@interface XCUIElement (FBAccessibility)

/*! Whether or not the element is accessible */
@property (atomic, readonly, getter = isFbAccessibilityElement) BOOL fbAccessibilityElement;

@end


@interface XCElementSnapshot (FBAccessibility)

/*! Whether or not the element in snapshot is accessible */
@property (atomic, readonly, getter = isFbAccessibilityElement) BOOL fbAccessibilityElement;

@end
