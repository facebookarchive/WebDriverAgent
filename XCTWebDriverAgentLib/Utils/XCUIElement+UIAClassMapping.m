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
    @"UIACollectionCell" : @(XCUIElementTypeCell),
    @"UIACollectionView" : @(XCUIElementTypeCollectionView),
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
    @"UIATableCell" : @(XCUIElementTypeTableRow),
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
  
  ElementTypeToUIAClassMapping = [self dictionaryWithKeysAndValuesSwapped:UIAClassToElementTypeMapping];
}

+ (XCUIElementType)elementTypeWithUIAClassName:(NSString *)className
{
  return (XCUIElementType)[UIAClassToElementTypeMapping[className] unsignedIntegerValue] ?: XCUIElementTypeAny;
}

+ (NSString *)UIAClassNameWithElementType:(XCUIElementType)elementType
{
  return ElementTypeToUIAClassMapping[@(elementType)] ?: @"UIAElement";
}

+ (NSDictionary *)dictionaryWithKeysAndValuesSwapped:(NSDictionary *)dictionary
{
  NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionary];
  [dictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
    mutableDictionary[obj] = key;
  }];
  return mutableDictionary.copy;
}

- (NSString *)UIAClassName
{
  return [self.class UIAClassNameWithElementType:self.elementType];
}

@end
