// Copyright 2004-present Facebook. All Rights Reserved.

#import <XCTWebDriverAgentLib/XCUIElement.h>

@class NSArray, NSDictionary, NSString, XCAccessibilityElement, XCApplicationQuery;

NS_ASSUME_NONNULL_BEGIN

NS_CLASS_AVAILABLE(10_11, 9_0)

/*! Proxy for an application. The information identifying the application is specified in the Xcode target settings as the "Target Application". */
@interface XCUIApplication : XCUIElement

/*!
 * Launches the application. This call is synchronous and when it returns the application is launched
 * and ready to handle user events. Any failure in the launch sequence is reported as a test failure
 * and halts the test at this point. If the application is already running, this call will first
 * terminate the existing instance to ensure clean state of the launched instance.
 */
- (void)launch;

/*!
 * Terminates any running instance of the application. If the application has an existing debug session
 * via Xcode, the termination is implemented as a halt via that debug connection. Otherwise, a SIGKILL
 * is sent to the process.
 */
- (void)terminate;

/*!
 * The arguments that will be passed to the application on launch. If not modified, these are the
 * arguments that Xcode will pass on launch. Those arguments can be changed, added to, or removed.
 * Unlike NSTask, it is legal to modify these arguments after the application has been launched. These
 * changes will not affect the current launch session, but will take effect the next time the application
 * is launched.
 *
 * Note: the arguments are reset to the default values for each test case.
 */
@property (nonatomic, copy) NSArray<NSString *> *launchArguments;

/*!
 * The environment that will be passed to the application on launch. If not modified, this is the
 * environment that Xcode will pass on launch. Those variables can be changed, added to, or removed.
 * Unlike NSTask, it is legal to modify the environment after the application has been launched. These
 * changes will not affect the current launch session, but will take effect the next time the application
 * is launched.
 *
 * Note: the environment is reset to the default values for each test case.
 */
@property (nonatomic, copy) NSDictionary<NSString *, NSString *> *launchEnvironment;

@end

@interface XCUIApplication ()
{
  _Bool _accessibilityActive;
  _Bool _ancillary;
  _Bool _eventLoopIsIdle;
  int _processID;
  unsigned long long _state;
  XCUIElement *_keyboard;
  NSArray *_launchArguments;
  NSDictionary *_launchEnvironment;
  NSString *_path;
  NSString *_bundleID;
  XCApplicationQuery *_applicationQuery;
  unsigned long long _generation;
}

+ (id)keyPathsForValuesAffectingRunning;
+ (id)appWithPID:(int)arg1;
@property (atomic, assign) unsigned long long generation; // @synthesize generation=_generation;
@property (atomic, assign) _Bool eventLoopIsIdle; // @synthesize eventLoopIsIdle=_eventLoopIsIdle;
@property (atomic, retain) XCApplicationQuery *applicationQuery;
@property (atomic, copy, readonly) NSString *bundleID;
@property (atomic, copy, readonly) NSString *path;
@property (atomic, assign) _Bool ancillary; // @synthesize ancillary=_ancillary;
@property (nonatomic, assign) _Bool accessibilityActive;
- (void)dismissKeyboard;
@property (atomic, readonly) XCUIElement *keyboard;
@property (readonly, nonatomic) UIInterfaceOrientation interfaceOrientation;
- (void)_waitForViewControllerViewDidDisappearWithTimeout:(double)arg1;
- (void)_waitForQuiescence;
- (void)terminate;
- (void)_launchUsingXcode:(_Bool)arg1;
- (void)launch;
- (void)_waitForLaunchProgressViaProxy:(id)arg1;
- (void)_waitForLaunchTokenViaProxy:(id)arg1;
- (id)application;
@property (readonly, nonatomic) _Bool running;
@property (nonatomic, assign) int processID;
@property (atomic, assign) unsigned long long state; // @synthesize state=_state;
- (id)description;
- (id)lastSnapshot;
- (id)query;
- (void)clearQuery;
@property (atomic, readonly) XCAccessibilityElement *accessibilityElement;
- (unsigned long long)elementType;
- (id)initPrivateWithPath:(id)arg1 bundleID:(id)arg2;
- (id)init;
- (void)dealloc;

@end

NS_ASSUME_NONNULL_END
