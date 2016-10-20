/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, FBCommandStatus){
    FBCommandStatusNoError = 0,
    FBCommandStatusUnsupported = 1,
    FBCommandStatusNoSuchSession = 6, //"A session is either terminated or not started")
    FBCommandStatusNoSuchElement = 7,// "An element could not be located on the page using the given search parameters")
    FBCommandStatusNoSuchFrame = 8, //"A request to switch to a frame could not be satisfied because the frame could not be found")
    FBCommandStatusUnknownCommand = 9, //"The requested resource could not be found, or a request was received using an HTTP method that is not supported by the mapped resource")
    FBCommandStatusStaleElementReference = 10,// "An element command failed because the referenced element is no longer attached to the DOM")
    FBCommandStatusElementNotVisible = 11,// "An element command could not be completed because the element is not visible on the page")
    FBCommandStatusInvalidElementState = 12, //"An element command could not be completed because the element is in an invalid state (e.g. attempting to click a disabled element)")
    FBCommandStatusUnhandled = 13, //"An unknown server-side error occurred while processing the command")
    FBCommandStatusElementNotSelectable = 15, //"An attempt was made to select an element that cannot be selected")
    FBCommandStatusInvalidArgument = 15, //"invalid argument")
    FBCommandStatusJavaScript = 17, //"An error occurred while executing user supplied JavaScript")
    FBCommandStatusXPathLookup = 19, //"An error occurred while searching for an element by XPath")
    FBCommandStatusTimeout = 21, //"An operation did not complete before its timeout expired")
    FBCommandStatusNoSuchWindow = 23, //"A request to switch to a different window could not be satisfied because the window could not be found")
    FBCommandStatusInvalidCookieDomain = 24, //"An illegal attempt was made to set a cookie under a different domain than the current page")
    FBCommandStatusUnableToSetCookie = 25, //"A request to set a cookie's value could not be satisfied")
    FBCommandStatusUnexpectedAlertPresent = 26,// "A modal dialog was open, blocking this operation")
    FBCommandStatusNoAlertPresent = 27,// "An attempt was made to operate on a modal dialog when one was not open")
    FBCommandStatusAsyncScriptTimeout = 28,// "A script did not complete before its timeout expired")
    FBCommandStatusInvalidCoordinates = 29, //"The coordinates provided to an interactions operation are invalid")
    FBCommandStatusImeNotAvailable = 30, //"IME was not available")
    FBCommandStatusImeEngineActivationFailed = 31,// "An IME engine could not be started")
    FBCommandStatusInvalidSelector = 32, //"Argument was an invalid selector (e.g. XPath/CSS)")
    FBCommandStatusSessionNotCreated = 33, //"A new session could not be created")
    FBCommandStatusMoveTargetOutOfBounds = 34, //"Target provided for a move action is out of bounds")
    FBCommandStatusInvalidXPathSelector = 51,// "Invalid XPath selector")
    FBCommandStatusInvalidXPathSelectorReturnType = 52,// "Invalid XPath selector return type")
    FBCommandStatusMethodNotAllowed = 405,// "Method not allowed")
    FBCommandStatusRotationNotAllowed = 777,// "Rotation not allowed")
    FBCommandStatusApplicationDeadlockDetected = 888,// "Application deadlock detected")
};
