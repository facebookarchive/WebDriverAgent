/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */


#import <Foundation/Foundation.h>

typedef void (^WDHTTPOverUSBResponse)(NSDictionary *response, NSError *requestError);

/**
 USB Client that connects and sends HTTP like requests over USB to WebDriverAgent launched on device with given UDID.
 */
@interface FBHTTPOverUSBClient : NSObject

/**
 Client constructor for device with given UDID
 */
- (instancetype)initWithDeviceUDID:(NSString *)deviceUDID;

/**
 Dispatches HTTP like request with given parameters, that calls 'completion' on WDA response

 @param method HTTP method name, like 'POST', 'GET', 'DELETE'
 @param endpoint HTTP endpoint/path that should be called, like /element/:id/name
 @param parameters HTTP parameters
 @param completion block called on WDA response to this request
 */
- (void)dispatchMethod:(NSString *)method endpoint:(NSString *)endpoint parameters:(NSDictionary *)parameters completion:(WDHTTPOverUSBResponse)completion;

@end
