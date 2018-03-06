/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBMathUtils.h"

#import "FBMacros.h"

CGFloat FBDefaultFrameFuzzyThreshold = 2.0;

CGPoint FBRectGetCenter(CGRect rect)
{
  return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

BOOL FBFloatFuzzyEqualToFloat(CGFloat float1, CGFloat float2, CGFloat threshold)
{
  return (fabs(float1 - float2) <= threshold);
}

BOOL FBPointFuzzyEqualToPoint(CGPoint point1, CGPoint point2, CGFloat threshold)
{
  return FBFloatFuzzyEqualToFloat(point1.x, point2.x, threshold) && FBFloatFuzzyEqualToFloat(point1.y, point2.y, threshold);
}

BOOL FBSizeFuzzyEqualToSize(CGSize size1, CGSize size2, CGFloat threshold)
{
  return FBFloatFuzzyEqualToFloat(size1.width, size2.width, threshold) && FBFloatFuzzyEqualToFloat(size1.height, size2.height, threshold);
}

BOOL FBRectFuzzyEqualToRect(CGRect rect1, CGRect rect2, CGFloat threshold)
{
  return
  FBPointFuzzyEqualToPoint(FBRectGetCenter(rect1), FBRectGetCenter(rect2), threshold) &&
  FBSizeFuzzyEqualToSize(rect1.size, rect2.size, threshold);
}

CGPoint FBInvertPointForApplication(CGPoint point, CGSize screenSize, UIInterfaceOrientation orientation)
{
  switch (orientation) {
    case UIInterfaceOrientationUnknown:
    case UIInterfaceOrientationPortrait:
      return point;
    case UIInterfaceOrientationPortraitUpsideDown:
      return CGPointMake(screenSize.width - point.x, screenSize.height - point.y);
    case UIInterfaceOrientationLandscapeLeft:
      return CGPointMake(point.y, screenSize.height - point.x);
    case UIInterfaceOrientationLandscapeRight:
      return CGPointMake(screenSize.width - point.y, point.x);
  }
}

CGPoint FBInvertOffsetForOrientation(CGPoint offset, UIInterfaceOrientation orientation)
{
  switch (orientation) {
    case UIInterfaceOrientationUnknown:
    case UIInterfaceOrientationPortrait:
      return offset;
    case UIInterfaceOrientationPortraitUpsideDown:
      return CGPointMake(-offset.x, -offset.y);
    case UIInterfaceOrientationLandscapeLeft:
      return CGPointMake(offset.y, -offset.x);
    case UIInterfaceOrientationLandscapeRight:
      return CGPointMake(-offset.y, offset.x);
  }
}

CGSize FBAdjustDimensionsForApplication(CGSize actualSize, UIInterfaceOrientation orientation)
{
  if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight) {
    /*
     There is an XCTest bug that application.frame property returns exchanged dimensions for landscape mode.
     This verification is just to make sure the bug is still there (since height is never greater than width in landscape) 
     and to make it still working properly after XCTest itself starts to respect landscape mode.
     */
    if (actualSize.height > actualSize.width) {
      return CGSizeMake(actualSize.height, actualSize.width);
    }
  }
  return actualSize;
}

NSData *FBAdjustScreenshotOrientationForApplication(NSData *screenshotData, UIInterfaceOrientation orientation)
{
  UIImage *image = [UIImage imageWithData:screenshotData];
  UIImageOrientation imageOrientation;
  if (SYSTEM_VERSION_LESS_THAN(@"11.0")) {
    // In iOS < 11.0 screenshots are already adjusted properly
    imageOrientation = UIImageOrientationUp;
  } else if (orientation == UIInterfaceOrientationLandscapeRight) {
    imageOrientation = UIImageOrientationLeft;
  } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
    imageOrientation = UIImageOrientationRight;
  } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
    imageOrientation = UIImageOrientationDown;
  } else {
    return (NSData *)UIImagePNGRepresentation(image);
  }
  
  UIGraphicsBeginImageContext(CGSizeMake(image.size.width, image.size.height));
  [[UIImage imageWithCGImage:(CGImageRef)[image CGImage] scale:1.0 orientation:imageOrientation]
   drawInRect:CGRectMake(0, 0, image.size.width, image.size.height)];
  UIImage *fixedImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  // The resulting data should be a PNG image
  return (NSData *)UIImagePNGRepresentation(fixedImage);
}

NSDictionary<NSString *, NSNumber *> *FBwdRectNoInf(NSDictionary<NSString *, NSNumber *> *wdRect)
{
  NSMutableDictionary<NSString *, NSNumber *> *result = wdRect.mutableCopy;
  if (isinf(result[@"x"].doubleValue) || isinf(result[@"y"].doubleValue) ||
      isinf(result[@"width"].doubleValue) || isinf(result[@"height"].doubleValue)) {
    [result setObject:@-1 forKey:@"x"];
    [result setObject:@-1 forKey:@"y"];
    [result setObject:@0 forKey:@"width"];
    [result setObject:@0 forKey:@"height"];
  }
  return result.copy;
}
