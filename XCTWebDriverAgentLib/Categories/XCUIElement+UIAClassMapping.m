/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "XCUIElement+UIAClassMapping.h"

#import "XCUIElement.h"
#import "XCUIElementQuery.h"

static NSDictionary *UIAClassToElementTypeMapping;
static NSDictionary *ElementTypeToUIAClassMapping;

@implementation XCUIElement (UIAClassMapping)

+ (void)load
{
  UIAClassToElementTypeMapping =
  @{
    @"UIAActionSheet" : @(XCUIElementTypeSheet),
    @"UIAActivityIndicator" : @(XCUIElementTypeActivityIndicator),
//    @"UIAActivityView"
    @"UIAAlert" : @(XCUIElementTypeAlert),
    @"UIAApplication" : @(XCUIElementTypeApplication),
    @"UIAButton" : @(XCUIElementTypeButton),
    @"UIACollectionView" : @(XCUIElementTypeCollectionView),
    @"UIACellView" : @(XCUIElementTypeCell),
    @"UIAImage" : @(XCUIElementTypeImage),
    @"UIAKey" : @(XCUIElementTypeKey),
    @"UIAKeyboard" : @(XCUIElementTypeKeyboard),
    @"UIALink" : @(XCUIElementTypeLink),
    @"UIANavigationBar" : @(XCUIElementTypeNavigationBar),
    @"UIAPageIndicator" : @(XCUIElementTypePageIndicator),
    @"UIAPicker" : @(XCUIElementTypePicker),
    @"UIAPickerWheel" : @(XCUIElementTypePickerWheel),
    @"UIAPopover" : @(XCUIElementTypePopover),
    @"UIAScrollView" : @(XCUIElementTypeScrollView),
    @"UIASearchBar" : @(XCUIElementTypeSearchField),
    @"UIASecureTextField" : @(XCUIElementTypeSecureTextField),
    @"UIASegmentedControl" : @(XCUIElementTypeSegmentedControl),
    @"UIASlider" : @(XCUIElementTypeSlider),
    @"UIAStaticText" : @(XCUIElementTypeStaticText),
    @"UIAStatusBar" : @(XCUIElementTypeStatusBar),
    @"UIASwitch" : @(XCUIElementTypeSwitch),
    @"UIATabBar" : @(XCUIElementTypeTabBar),
    @"UIATableGroup" : @(XCUIElementTypeTableColumn), //?
    @"UIATableView" : @(XCUIElementTypeTable),
    @"UIATextField" : @(XCUIElementTypeTextField),
    @"UIATextView" : @(XCUIElementTypeTextView),
    @"UIAToolbar" : @(XCUIElementTypeToolbar),
    @"UIAWebView" : @(XCUIElementTypeWebView),
    @"UIAWindow" : @(XCUIElementTypeWindow),
    @"UIAElement" : @(XCUIElementTypeAny),
    //@"" : @(XCUIElementTypeGroup),
    //@"" : @(XCUIElementTypeDrawer),
    //@"" : @(XCUIElementTypeDialog),
    //@"" : @(XCUIElementTypeRadioButton),
    //@"" : @(XCUIElementTypeRadioGroup),
    //@"" : @(XCUIElementTypeCheckBox),
    //@"" : @(XCUIElementTypeDisclosureTriangle),
    //@"" : @(XCUIElementTypePopUpButton),
    //@"" : @(XCUIElementTypeComboBox),
    //@"" : @(XCUIElementTypeMenuButton),
    //@"" : @(XCUIElementTypeToolbarButton),
    //@"" : @(XCUIElementTypeTabGroup),
    //@"" : @(XCUIElementTypeOutline),
    //@"" : @(XCUIElementTypeOutlineRow),
    //@"" : @(XCUIElementTypeBrowser),
    //@"" : @(XCUIElementTypeProgressIndicator),
    //@"" : @(XCUIElementTypeToggle),
    //@"" : @(XCUIElementTypeIcon),
    //@"" : @(XCUIElementTypeScrollBar),
    //@"" : @(XCUIElementTypeDatePicker),
    //@"" : @(XCUIElementTypeMenu),
    //@"" : @(XCUIElementTypeMenuItem),
    //@"" : @(XCUIElementTypeMenuBar),
    //@"" : @(XCUIElementTypeMenuBarItem),
    //@"" : @(XCUIElementTypeMap),
    //@"" : @(XCUIElementTypeIncrementArrow),
    //@"" : @(XCUIElementTypeDecrementArrow),
    //@"" : @(XCUIElementTypeTimeline),
    //@"" : @(XCUIElementTypeRatingIndicator),
    //@"" : @(XCUIElementTypeValueIndicator),
    //@"" : @(XCUIElementTypeSplitGroup),
    //@"" : @(XCUIElementTypeSplitter),
    //@"" : @(XCUIElementTypeRelevanceIndicator),
    //@"" : @(XCUIElementTypeColorWell),
    //@"" : @(XCUIElementTypeHelpTag),
    //@"" : @(XCUIElementTypeMatte),
    //@"" : @(XCUIElementTypeDockItem),
    //@"" : @(XCUIElementTypeRuler),
    //@"" : @(XCUIElementTypeRulerMarker),
    //@"" : @(XCUIElementTypeGrid),
    //@"" : @(XCUIElementTypeLevelIndicator),
    //@"" : @(XCUIElementTypeLayoutArea),
    //@"" : @(XCUIElementTypeLayoutItem),
    //@"" : @(XCUIElementTypeHandle),
    //@"" : @(XCUIElementTypeStepper),
    //@"" : @(XCUIElementTypeTab),
    };
  NSMutableDictionary *swappedMapping = [NSMutableDictionary dictionary];
  [UIAClassToElementTypeMapping enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
    swappedMapping[obj] = key;
  }];
  ElementTypeToUIAClassMapping = swappedMapping.copy;
}

+ (XCUIElementType)elementTypeWithUIAClassName:(NSString *)className
{
  NSNumber *type = UIAClassToElementTypeMapping[className];
  if (type) {
    return (XCUIElementType)[type unsignedIntegerValue];
  }
  const BOOL isCellType = ([className isEqualToString:@"UIATableCell"] || [className isEqualToString:@"UIACollectionCell"]);
  if (isCellType) {
    return XCUIElementTypeCell;
  }
  return XCUIElementTypeAny;
}

+ (NSString *)UIAClassNameWithElementType:(XCUIElementType)elementType
{
  return ElementTypeToUIAClassMapping[@(elementType)] ?: @"UIAElement";
}

+ (NSString *)patchXPathQueryUIAClassNames:(NSString *)xpath
{
  /* TODO: t9218527
     This is oversimplified approach that would work for massive majority of test cases.
     It will fail for xpaths like "//UIAWindow// *[@label = 'UIACollectionCell']" so apps that contain 'UIATableCell' and 'UIACollectionCell' strings
   */
  NSMutableString *mutableXPath = xpath.mutableCopy;
  [mutableXPath replaceOccurrencesOfString:@"UIATableCell" withString:@"UIACellView" options:NSLiteralSearch range:NSMakeRange(0, mutableXPath.length)];
  [mutableXPath replaceOccurrencesOfString:@"UIACollectionCell" withString:@"UIACellView" options:NSLiteralSearch range:NSMakeRange(0, mutableXPath.length)];
  return mutableXPath.copy;
}

- (NSString *)UIAClassName
{
  return [self.class UIAClassNameWithElementType:self.elementType];
}

@end
