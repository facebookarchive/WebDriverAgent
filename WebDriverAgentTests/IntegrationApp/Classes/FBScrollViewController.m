/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBScrollViewController.h"

#import "FBTableDataSource.h"

static const CGFloat FBSubviewHeight = 40.0;

@interface FBScrollViewController ()
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) IBOutlet FBTableDataSource *dataSource;
@end

@implementation FBScrollViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  [self setupLabelViews];
  self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame), self.dataSource.count * FBSubviewHeight);
}

- (void)setupLabelViews
{
  NSUInteger count = self.dataSource.count;
  for (NSInteger i = 0 ; i < count ; i++) {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, i * FBSubviewHeight, CGRectGetWidth(self.view.frame), FBSubviewHeight)];
    label.text = [self.dataSource textForElementAtIndex:i];
    label.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:label];
  }
}

@end
