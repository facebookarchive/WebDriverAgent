/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>

#if defined(__cplusplus)
#define XCT_EXPORT extern "C"
#else
#define XCT_EXPORT extern
#endif

#if __has_feature(objc_generics)
#define XCT_GENERICS_AVAILABLE 1
#endif

#if __has_feature(nullability)
#define XCT_NULLABLE_AVAILABLE 1
#endif

#if (!defined(__OBJC_GC__) || (defined(__OBJC_GC__) && ! __OBJC_GC__)) && (defined(__OBJC2__) && __OBJC2__) && (!defined (TARGET_OS_WATCH) || (defined(TARGET_OS_WATCH) && ! TARGET_OS_WATCH))
#ifndef XCT_UI_TESTING_AVAILABLE
#define XCT_UI_TESTING_AVAILABLE 1
#endif
#endif

#ifndef XCT_NULLABLE_AVAILABLE
#define XCT_NULLABLE_AVAILABLE 0
#endif

#ifndef XCT_GENERICS_AVAILABLE
#define XCT_GENERICS_AVAILABLE 0
#endif

#ifndef XCT_UI_TESTING_AVAILABLE
#define XCT_UI_TESTING_AVAILABLE 0
#endif

#if TARGET_OS_SIMULATOR
#define XCTEST_SIMULATOR_UNAVAILABLE(_msg) __attribute__((availability(ios,unavailable,message=_msg)))
#else
#define XCTEST_SIMULATOR_UNAVAILABLE(_msg)
#endif


NS_ASSUME_NONNULL_BEGIN

/*!
 * @enum XCUIDeviceButton
 *
 * Represents a physical button on a device.
 *
 * @note Some buttons are not available in the Simulator, and should not be used in your tests.
 * You can use a block like this:
 *
 *     #if !TARGET_OS_SIMULATOR
 *     // test code that depends on buttons not available in the Simulator
 *     #endif
 *
 * in your test code to ensure it does not call unavailable APIs.
 */
typedef NS_ENUM(NSInteger, XCUIDeviceButton) {
  XCUIDeviceButtonHome = 1,
  XCUIDeviceButtonVolumeUp XCTEST_SIMULATOR_UNAVAILABLE("This API is not available in the Simulator, see the XCUIDeviceButton documentation for details.") = 2,
  XCUIDeviceButtonVolumeDown XCTEST_SIMULATOR_UNAVAILABLE("This API is not available in the Simulator, see the XCUIDeviceButton documentation for details.") = 3
};

/*! Represents a device, providing an interface for simulating events involving physical buttons and device state. */
NS_CLASS_AVAILABLE(NA, 9_0)
@interface XCUIDevice : NSObject

/*! The current device. */
+ (XCUIDevice *)sharedDevice;

/*! The orientation of the device. */
@property (nonatomic, assign) UIDeviceOrientation orientation;

/*! Simulates the user pressing a physical button. */
- (void)pressButton:(XCUIDeviceButton)button;

@end

@interface XCUIDevice ()
- (void)pressLockButton;
- (void)holdHomeButtonForDuration:(double)arg1;
- (void)_silentPressButton:(long long)arg1;
- (void)_dispatchEventWithPage:(unsigned int)arg1 usage:(unsigned int)arg2 duration:(double)arg3;

@end


NS_ASSUME_NONNULL_END
