/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBInvisibleParentScrollingController.h"
#import "FBTableDataSource.h"

static const CGFloat FBSubviewHeight = 40.0;

@interface FBInvisibleParentScrollingController ()
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet FBTableDataSource *dataSource;

@end
@implementation FBInvisibleParentScrollingController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLabelViews];
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame), self.dataSource.count * FBSubviewHeight + 800);
}

- (void)setupLabelViews
{
    NSUInteger count = 15;
    for (NSUInteger i = 0 ; i < count ; i++) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, i * FBSubviewHeight, CGRectGetWidth(self.view.frame), FBSubviewHeight)];
        label.text = [self.dataSource textForElementAtIndex:i];
        label.textAlignment = NSTextAlignmentCenter;
        [self.scrollView addSubview:label];
    }
    UIScrollView *innerScrollview = [[UIScrollView alloc] initWithFrame:CGRectMake(0, (count + 1) * FBSubviewHeight, CGRectGetWidth(self.view.frame), FBSubviewHeight + 300)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(innerScrollview.frame), FBSubviewHeight)];
    label.text = @"WDA";
    label.textAlignment = NSTextAlignmentCenter;
    [innerScrollview addSubview:label];
    [self.scrollView addSubview:innerScrollview];
}

@end
