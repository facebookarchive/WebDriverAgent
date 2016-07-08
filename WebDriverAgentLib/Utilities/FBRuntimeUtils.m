/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBRuntimeUtils.h"

#include <dlfcn.h>
#import <objc/runtime.h>

NSArray<Class> *FBClassesThatConformsToProtocol(Protocol *protocol)
{
  Class *classes = NULL;
  NSMutableArray *collection = [NSMutableArray array];
  int numClasses = objc_getClassList(NULL, 0);
  if (numClasses == 0 ) {
    return @[];
  }

  classes = (__unsafe_unretained Class*)malloc(sizeof(Class) * numClasses);
  numClasses = objc_getClassList(classes, numClasses);
  for (int index = 0; index < numClasses; index++) {
    Class aClass = classes[index];
    if (class_conformsToProtocol(aClass, protocol)) {
      [collection addObject:aClass];
    }
  }
  free(classes);
  return collection.copy;
}

void *FBRetrieveSymbolFromBinary(const char *binary, const char *name)
{
  void *handle = dlopen(binary, RTLD_LAZY);
  NSCAssert(handle, @"%s could not be opened", binary);
  void *pointer = dlsym(handle, name);
  NSCAssert(pointer, @"%s could not be located", name);
  return pointer;
}
