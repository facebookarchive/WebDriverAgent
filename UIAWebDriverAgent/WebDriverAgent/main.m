/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIAWebDriverAgentLib/FBUIAWebDriverAgent.h>

#import <dlfcn.h>
#import <fishhook/fishhook.h>

void my_free(void *ptr);
static void (*orig_free)(void *);

static void *badFreeCaller;

void my_free(void *ptr) {
  void *caller = __builtin_return_address(0);
  if (caller == badFreeCaller) {
    return;
  }
  orig_free(ptr);
}


int main(int argc, char *argv[]) {
  @autoreleasepool {
    // This is all one terrible hack to deal with a bug in AXRuntime cfAttributedStringUnserialize() where they attempt
    // to free a pointer which was not allocated.
    // From doing pointer arithmetic, at the end of this `badFreeCaller` is set to the exact address of the caller which attempts
    // this within cfAttributedStringUnserialize.
    // This issue shows up in Xcode 7.2.
    rebind_symbols((struct rebinding[1]){{"free", my_free, (void *)&orig_free}}, 1);
    void *AXRuntimeImage = dlopen("/System/Library/PrivateFrameworks/AXRuntime.framework/AXRuntime", RTLD_NOW);
    void *knownAddress = dlsym(AXRuntimeImage, "AXUnserializeCFType");
    badFreeCaller = knownAddress + 0x1F69;

    [[FBUIAWebDriverAgent sharedAgent] start];
  }

  return 0;
}
