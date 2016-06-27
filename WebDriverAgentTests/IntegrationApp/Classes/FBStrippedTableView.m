// Copyright 2004-present Facebook. All Rights Reserved.

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
