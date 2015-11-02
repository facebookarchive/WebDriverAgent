//
//  Copyright 2004-present Facebook. All Rights Reserved.
//

#import <XCTWebDriverAgentLib/XCUIElementTypes.h>

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, XCUIUserInterfaceSizeClass) {
  XCUIUserInterfaceSizeClassUnspecified = UIUserInterfaceSizeClassUnspecified,
  XCUIUserInterfaceSizeClassCompact     = UIUserInterfaceSizeClassCompact,
  XCUIUserInterfaceSizeClassRegular     = UIUserInterfaceSizeClassRegular,
};

NS_ASSUME_NONNULL_BEGIN

/*! Protocol describing the attributes exposed on user interface elements and available during query matching. These attributes represent data exposed to the Accessibility system. */
@protocol XCUIElementAttributes

/*! The accessibility identifier. */
@property (atomic, copy, readonly) NSString *identifier;

/*! The frame of the element in the screen coordinate space. */
@property (atomic, readonly) CGRect frame;

/*! The raw value attribute of the element. Depending on the element, the actual type can vary. */
@property (atomic, readonly, nullable) id value;

/*! The title attribute of the element. */
@property (atomic, copy, readonly) NSString *title;

/*! The label attribute of the element. */
@property (atomic, copy, readonly) NSString *label;

/*! The type of the element. /seealso XCUIElementType. */
@property (atomic, readonly) XCUIElementType elementType;

/*! Whether or not the element is enabled for user interaction. */
@property (atomic, readonly, getter = isEnabled) BOOL enabled;

/*! The horizontal size class of the element. */
@property (atomic, readonly) XCUIUserInterfaceSizeClass horizontalSizeClass;

/*! The vertical size class of the element. */
@property (atomic, readonly) XCUIUserInterfaceSizeClass verticalSizeClass;

/*! The value that is displayed when the element has no value. */
@property (atomic, copy, readonly, nullable) NSString *placeholderValue;

/*! Whether or not the element is selected. */
@property (atomic, readonly, getter = isSelected) BOOL selected;

@end

NS_ASSUME_NONNULL_END
