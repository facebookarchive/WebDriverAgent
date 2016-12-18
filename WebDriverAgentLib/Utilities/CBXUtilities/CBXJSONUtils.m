
#import "CBXJSONUtils.h"
#import "XCUIElement+FBWebDriverAttributes.h"
#import "FBElementCache.h"
#import "FBSession.h"

@implementation CBXJSONUtils
static NSDictionary <NSNumber *, NSString *> *elementTypeToString;
static NSDictionary <NSString *, NSNumber *> *typeStringToElementType;

+ (NSDictionary *)elementToJSON:(XCUIElement *)element {
    if (!element.exists) {
        //Who knows what can go wrong if we pry into a non-existant element.
        //Fail fast.
        return @{@"error" : @"element does not exist"};
    }
    NSMutableDictionary *json = [NSMutableDictionary dictionary];
    json[@"type"] = element.wdType ?: @"";
    json[@"label"] = element.wdLabel ?: @"";
    json[@"name"] = element.wdName ?: @"";
    json[@"value"] = element.wdValue ?: @"";
    json[@"frame"] = json[@"rect"] = element.wdRect;
    json[@"id"] = element.identifier ?: @"";
    json[@"enabled"] = @(element.wdEnabled);
    json[@"visible"] = @(element.wdVisible);
    json[@"hitable"] = @([self elementHitable:element]);
    json[@"hit_point"] = [self elementHitPointToJSON:element];
    json[@"ELEMENT"] = [[FBSession activeSessionCache] storeElement:element];
    return json;
}

+ (BOOL)elementHitable:(XCUIElement *)element {
    if (![element respondsToSelector:@selector(isHittable)]) {
        return NO;
    } else {
        return [element isHittable];
    }
}

+ (NSDictionary *)elementHitPointToJSON:(XCUIElement *)element {
    id hitPoint = nil;
    XCUICoordinate *coordinate = nil;
    NSDictionary *dictionary = nil;
    if ([element respondsToSelector:@selector(hitPointCoordinate)]) {
        hitPoint = [element hitPointCoordinate];
        if (hitPoint) {
            if ([hitPoint respondsToSelector:@selector(screenPoint)]) {
                
                coordinate = (XCUICoordinate *)hitPoint;
                CGPoint point = [coordinate screenPoint];
                dictionary = @{ @"x" : @(point.x), @"y": @(point.y) };
            }
        }
    }
    
    return dictionary ?: @{ @"x" : @(-1), @"y" : @(-1) };
}

+ (NSString *)objToJSONString:(id)objcJsonObject {
    if (!objcJsonObject) {
        return @"";
    }
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:objcJsonObject
                                                       options:(NSJSONWritingOptions)0
                                                         error:&error];
    if (error) {
        NSLog(@"Error: %@", error);
        return error.localizedDescription;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    return jsonString;
}


+ (XCUIElementType)elementTypeForString:(NSString *)typeString {
    NSNumber *typeNumber = typeStringToElementType[[typeString lowercaseString]];
    if (typeNumber) {
        return [typeNumber unsignedIntegerValue];
    }
    @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                   reason:@"Invalid Element Type"
                                 userInfo:@{@"type" : typeString}];
}

+ (NSString *)stringForElementType:(XCUIElementType)type {
    return elementTypeToString[@(type)];
}

+ (void)load {
    static dispatch_once_t oncet;
    dispatch_once(&oncet, ^{
        elementTypeToString = @{
                                @(XCUIElementTypeAny) : @"Any",
                                @(XCUIElementTypeOther) : @"Other",
                                @(XCUIElementTypeApplication) : @"Application",
                                @(XCUIElementTypeGroup) : @"Group",
                                @(XCUIElementTypeWindow) : @"Window",
                                @(XCUIElementTypeSheet) : @"Sheet",
                                @(XCUIElementTypeDrawer) : @"Drawer",
                                @(XCUIElementTypeAlert) : @"Alert",
                                @(XCUIElementTypeDialog) : @"Dialog",
                                @(XCUIElementTypeButton) : @"Button",
                                @(XCUIElementTypeRadioButton) : @"RadioButton",
                                @(XCUIElementTypeRadioGroup) : @"RadioGroup",
                                @(XCUIElementTypeCheckBox) : @"CheckBox",
                                @(XCUIElementTypeDisclosureTriangle) : @"DisclosureTriangle",
                                @(XCUIElementTypePopUpButton) : @"PopUpButton",
                                @(XCUIElementTypeComboBox) : @"ComboBox",
                                @(XCUIElementTypeMenuButton) : @"MenuButton",
                                @(XCUIElementTypeToolbarButton) : @"ToolbarButton",
                                @(XCUIElementTypePopover) : @"Popover",
                                @(XCUIElementTypeKeyboard) : @"Keyboard",
                                @(XCUIElementTypeKey) : @"Key",
                                @(XCUIElementTypeNavigationBar) : @"NavigationBar",
                                @(XCUIElementTypeTabBar) : @"TabBar",
                                @(XCUIElementTypeTabGroup) : @"TabGroup",
                                @(XCUIElementTypeToolbar) : @"Toolbar",
                                @(XCUIElementTypeStatusBar) : @"StatusBar",
                                @(XCUIElementTypeTable) : @"Table",
                                @(XCUIElementTypeTableRow) : @"TableRow",
                                @(XCUIElementTypeTableColumn) : @"TableColumn",
                                @(XCUIElementTypeOutline) : @"Outline",
                                @(XCUIElementTypeOutlineRow) : @"OutlineRow",
                                @(XCUIElementTypeBrowser) : @"Browser",
                                @(XCUIElementTypeCollectionView) : @"CollectionView",
                                @(XCUIElementTypeSlider) : @"Slider",
                                @(XCUIElementTypePageIndicator) : @"PageIndicator",
                                @(XCUIElementTypeProgressIndicator) : @"ProgressIndicator",
                                @(XCUIElementTypeActivityIndicator) : @"ActivityIndicator",
                                @(XCUIElementTypeSegmentedControl) : @"SegmentedControl",
                                @(XCUIElementTypePicker) : @"Picker",
                                @(XCUIElementTypePickerWheel) : @"PickerWheel",
                                @(XCUIElementTypeSwitch) : @"Switch",
                                @(XCUIElementTypeToggle) : @"Toggle",
                                @(XCUIElementTypeLink) : @"Link",
                                @(XCUIElementTypeImage) : @"Image",
                                @(XCUIElementTypeIcon) : @"Icon",
                                @(XCUIElementTypeSearchField) : @"SearchField",
                                @(XCUIElementTypeScrollView) : @"ScrollView",
                                @(XCUIElementTypeScrollBar) : @"ScrollBar",
                                @(XCUIElementTypeStaticText) : @"StaticText",
                                @(XCUIElementTypeTextField) : @"TextField",
                                @(XCUIElementTypeSecureTextField) : @"SecureTextField",
                                @(XCUIElementTypeDatePicker) : @"DatePicker",
                                @(XCUIElementTypeTextView) : @"TextView",
                                @(XCUIElementTypeMenu) : @"Menu",
                                @(XCUIElementTypeMenuItem) : @"MenuItem",
                                @(XCUIElementTypeMenuBar) : @"MenuBar",
                                @(XCUIElementTypeMenuBarItem) : @"MenuBarItem",
                                @(XCUIElementTypeMap) : @"Map",
                                @(XCUIElementTypeWebView) : @"WebView",
                                @(XCUIElementTypeIncrementArrow) : @"IncrementArrow",
                                @(XCUIElementTypeDecrementArrow) : @"DecrementArrow",
                                @(XCUIElementTypeTimeline) : @"TimeLine",
                                @(XCUIElementTypeRatingIndicator) : @"RatingIndicator",
                                @(XCUIElementTypeValueIndicator) : @"ValueIndicator",
                                @(XCUIElementTypeSplitGroup) : @"SplitGroupe",
                                @(XCUIElementTypeSplitter) : @"Splitter",
                                @(XCUIElementTypeRelevanceIndicator) : @"RelevanceIndicator",
                                @(XCUIElementTypeColorWell) : @"ColorWell",
                                @(XCUIElementTypeHelpTag) : @"HelpTag",
                                @(XCUIElementTypeMatte) : @"Matte",
                                @(XCUIElementTypeDockItem) : @"DockItem",
                                @(XCUIElementTypeRuler) : @"Ruler",
                                @(XCUIElementTypeRulerMarker) : @"RulerMarker",
                                @(XCUIElementTypeGrid) : @"Grid",
                                @(XCUIElementTypeLevelIndicator) : @"LevelIndicator",
                                @(XCUIElementTypeCell) : @"Cell",
                                @(XCUIElementTypeLayoutArea) : @"LayoutArea",
                                @(XCUIElementTypeLayoutItem) : @"LayoutItem",
                                @(XCUIElementTypeHandle) : @"Handle",
                                @(XCUIElementTypeStepper) : @"Stepper",
                                @(XCUIElementTypeTab) : @"Tab",
                                };
        NSMutableDictionary *_typeStringToElementType = [NSMutableDictionary dictionaryWithCapacity:elementTypeToString.count];
        for (NSNumber *type in elementTypeToString) {
            NSString *typeString = [elementTypeToString[type] lowercaseString];
            _typeStringToElementType[typeString] = type;
        }
        typeStringToElementType = _typeStringToElementType;
    });
}

@end

@implementation NSArray(CBXExtensions)
- (NSString *)pretty {
    return [CBXJSONUtils objToJSONString:self];
}
@end

@implementation NSDictionary(CBXExtensions)
- (NSString *)pretty {
    return [CBXJSONUtils objToJSONString:self];
}

- (BOOL)hasKey:(NSString *)key {
    return [[self allKeys] containsObject:key];
}
@end
