/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "FBElementTypeTransformer.h"

#import "FBExceptionHandler.h"

@implementation FBElementTypeTransformer

static NSDictionary *ElementTypeToStringMapping;
static NSDictionary *StringToElementTypeMapping;

+ (void)createMapping
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    ElementTypeToStringMapping =
    @{
      @0 : @"XCUIElementTypeAny",
      @1 : @"XCUIElementTypeOther",
      @2 : @"XCUIElementTypeApplication",
      @3 : @"XCUIElementTypeGroup",
      @4 : @"XCUIElementTypeWindow",
      @5 : @"XCUIElementTypeSheet",
      @6 : @"XCUIElementTypeDrawer",
      @7 : @"XCUIElementTypeAlert",
      @8 : @"XCUIElementTypeDialog",
      @9 : @"XCUIElementTypeButton",
      @10 : @"XCUIElementTypeRadioButton",
      @11 : @"XCUIElementTypeRadioGroup",
      @12 : @"XCUIElementTypeCheckBox",
      @13 : @"XCUIElementTypeDisclosureTriangle",
      @14 : @"XCUIElementTypePopUpButton",
      @15 : @"XCUIElementTypeComboBox",
      @16 : @"XCUIElementTypeMenuButton",
      @17 : @"XCUIElementTypeToolbarButton",
      @18 : @"XCUIElementTypePopover",
      @19 : @"XCUIElementTypeKeyboard",
      @20 : @"XCUIElementTypeKey",
      @21 : @"XCUIElementTypeNavigationBar",
      @22 : @"XCUIElementTypeTabBar",
      @23 : @"XCUIElementTypeTabGroup",
      @24 : @"XCUIElementTypeToolbar",
      @25 : @"XCUIElementTypeStatusBar",
      @26 : @"XCUIElementTypeTable",
      @27 : @"XCUIElementTypeTableRow",
      @28 : @"XCUIElementTypeTableColumn",
      @29 : @"XCUIElementTypeOutline",
      @30 : @"XCUIElementTypeOutlineRow",
      @31 : @"XCUIElementTypeBrowser",
      @32 : @"XCUIElementTypeCollectionView",
      @33 : @"XCUIElementTypeSlider",
      @34 : @"XCUIElementTypePageIndicator",
      @35 : @"XCUIElementTypeProgressIndicator",
      @36 : @"XCUIElementTypeActivityIndicator",
      @37 : @"XCUIElementTypeSegmentedControl",
      @38 : @"XCUIElementTypePicker",
      @39 : @"XCUIElementTypePickerWheel",
      @40 : @"XCUIElementTypeSwitch",
      @41 : @"XCUIElementTypeToggle",
      @42 : @"XCUIElementTypeLink",
      @43 : @"XCUIElementTypeImage",
      @44 : @"XCUIElementTypeIcon",
      @45 : @"XCUIElementTypeSearchField",
      @46 : @"XCUIElementTypeScrollView",
      @47 : @"XCUIElementTypeScrollBar",
      @48 : @"XCUIElementTypeStaticText",
      @49 : @"XCUIElementTypeTextField",
      @50 : @"XCUIElementTypeSecureTextField",
      @51 : @"XCUIElementTypeDatePicker",
      @52 : @"XCUIElementTypeTextView",
      @53 : @"XCUIElementTypeMenu",
      @54 : @"XCUIElementTypeMenuItem",
      @55 : @"XCUIElementTypeMenuBar",
      @56 : @"XCUIElementTypeMenuBarItem",
      @57 : @"XCUIElementTypeMap",
      @58 : @"XCUIElementTypeWebView",
      @59 : @"XCUIElementTypeIncrementArrow",
      @60 : @"XCUIElementTypeDecrementArrow",
      @61 : @"XCUIElementTypeTimeline",
      @62 : @"XCUIElementTypeRatingIndicator",
      @63 : @"XCUIElementTypeValueIndicator",
      @64 : @"XCUIElementTypeSplitGroup",
      @65 : @"XCUIElementTypeSplitter",
      @66 : @"XCUIElementTypeRelevanceIndicator",
      @67 : @"XCUIElementTypeColorWell",
      @68 : @"XCUIElementTypeHelpTag",
      @69 : @"XCUIElementTypeMatte",
      @70 : @"XCUIElementTypeDockItem",
      @71 : @"XCUIElementTypeRuler",
      @72 : @"XCUIElementTypeRulerMarker",
      @73 : @"XCUIElementTypeGrid",
      @74 : @"XCUIElementTypeLevelIndicator",
      @75 : @"XCUIElementTypeCell",
      @76 : @"XCUIElementTypeLayoutArea",
      @77 : @"XCUIElementTypeLayoutItem",
      @78 : @"XCUIElementTypeHandle",
      @79 : @"XCUIElementTypeStepper",
      @80 : @"XCUIElementTypeTab",
      };
    NSMutableDictionary *swappedMapping = [NSMutableDictionary dictionary];
    [ElementTypeToStringMapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
      swappedMapping[obj] = key;
    }];
    StringToElementTypeMapping = swappedMapping.copy;
  });
}

+ (XCUIElementType)elementTypeWithTypeName:(NSString *)typeName
{
  [self createMapping];
  NSNumber *type = StringToElementTypeMapping[typeName];
  if (!type) {
    NSString *reason = [NSString stringWithFormat:@"Invalid argument for class used '%@'. Did you mean XCUIElementType%@?", typeName, typeName];
    @throw [NSException exceptionWithName:FBInvalidArgumentException reason:reason userInfo:@{}];
  }
  return (XCUIElementType) ( type ? type.unsignedIntegerValue : XCUIElementTypeAny);
}

+ (NSString *)stringWithElementType:(XCUIElementType)type
{
  [self createMapping];
  NSString *typeName = ElementTypeToStringMapping[@(type)];
  if (!typeName) {
    return [NSString stringWithFormat:@"Unknown(%lu)", (unsigned long)type];
  }
  return typeName;
}

+ (NSString *)shortStringWithElementType:(XCUIElementType)type
{
  return [[self stringWithElementType:type] stringByReplacingOccurrencesOfString:@"XCUIElementType" withString:@""];
}

@end
