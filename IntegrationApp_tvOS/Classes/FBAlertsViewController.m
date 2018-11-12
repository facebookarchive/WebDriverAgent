/**
 * Copyright (c) 2018-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBAlertsViewController.h"
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>

@interface FBAlertsViewController ()
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation FBAlertsViewController

- (IBAction)createAppAlert:(UIButton *)sender
{
  [self presentAlertController];
}

- (IBAction)createAppSheet:(UIButton *)sender
{
  UIAlertController *alerController =
  [UIAlertController alertControllerWithTitle:@"Magic Sheet"
                                      message:@"Should read"
                               preferredStyle:UIAlertControllerStyleActionSheet];
  [self presentViewController:alerController animated:YES completion:nil];
  
}

- (IBAction)createCameraRollAccessAlert:(UIButton *)sender
{
  [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
  }];
}

- (IBAction)createGPSAccessAlert:(UIButton *)sender
{
  self.locationManager = [CLLocationManager new];
  [self.locationManager requestWhenInUseAuthorization];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  for (UITouch *touch in touches) {
    if (fabs(touch.maximumPossibleForce - touch.force) < 0.0001) {
      [self presentAlertController];
    }
  }
}

- (void)presentAlertController {
  UIAlertController *alerController =
  [UIAlertController alertControllerWithTitle:@"Magic"
                                      message:@"Should read"
                               preferredStyle:UIAlertControllerStyleAlert];
  [alerController addAction:[UIAlertAction actionWithTitle:@"Will do" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alerController animated:YES completion:nil];
}

@end
