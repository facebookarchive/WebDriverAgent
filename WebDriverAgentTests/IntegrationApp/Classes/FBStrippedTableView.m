/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBStrippedTableView.h"

@interface FBStrippedTableView ()

@end

@implementation FBStrippedTableView

- (BOOL)isAccessibilityElement
{
  return NO;
}

- (NSInteger)accessibilityElementCount
{
  return [self.dataSource tableView:self numberOfRowsInSection:0];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
  return [self.dataSource tableView:self cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]].textLabel;
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
  if ([element isKindOfClass:[UITableViewCell class]]) {
    return ((UITableViewCell *)element).textLabel.text.integerValue;
  }
  return NSNotFound;
}

@end
