// Copyright 2004-present Facebook. All Rights Reserved.

#import "FBAlertViewController.h"

#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>

@interface FBAlertViewController ()
@property (nonatomic, strong) CLLocationManager *locationManager;
@end

@implementation FBAlertViewController

- (IBAction)createAppAlert:(UIButton *)sender
{
  UIAlertController *alerController =
  [UIAlertController alertControllerWithTitle:@"Magic"
                                      message:@"Should read"
                               preferredStyle:UIAlertControllerStyleAlert];
  [alerController addAction:[UIAlertAction actionWithTitle:@"Will do" style:UIAlertActionStyleDefault handler:nil]];
  [self presentViewController:alerController animated:YES completion:nil];
}

- (IBAction)createAppSheet:(UIButton *)sender
{
    UIAlertController *alerController =
    [UIAlertController alertControllerWithTitle:@"Magic Sheet"
                                        message:@"Should read"
                                 preferredStyle:UIAlertControllerStyleActionSheet];
    UIPopoverPresentationController *popPresenter = [alerController popoverPresentationController];
    popPresenter.sourceView = sender;
    [self presentViewController:alerController animated:YES completion:nil];
    
}

- (IBAction)createNotificationAlert:(UIButton *)sender
{
  [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert categories:nil]];
}

- (IBAction)createCameraRollAccessAlert:(UIButton *)sender
{
  [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
  }];
}

- (IBAction)createGPSAccessAlert:(UIButton *)sender
{
  self.locationManager = [CLLocationManager new];
  [self.locationManager requestAlwaysAuthorization];
}

@end
