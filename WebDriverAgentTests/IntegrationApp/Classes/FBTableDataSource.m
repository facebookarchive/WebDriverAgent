/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBTableDataSource.h"

@implementation FBTableDataSource

- (NSUInteger)count
{
  return 100;
}

- (NSString *)textForElementAtIndex:(NSInteger)index
{
  return [NSString stringWithFormat:@"%ld", (long)index];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  return self.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
  cell.textLabel.text = [self textForElementAtIndex:indexPath.row];
  return cell;
}

@end
