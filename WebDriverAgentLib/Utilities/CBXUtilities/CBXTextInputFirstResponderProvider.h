#import <Foundation/Foundation.h>

@class XCUIElement;

/**
 * A class for finding the TextInput view that is the first responder.
 */
@interface CBXTextInputFirstResponderProvider : NSObject

/**
 * Queries the AUT for the TextField, TextView, SecureTextField, or Other element type
 * for the XCUIElement that has keyboard focus.
 * @return the XCUIElement with keyboard focus or nil.
 */
- (XCUIElement *)firstResponder;

/**
 * Queries the AUT for the TextField, TextView, SecureTextField, or Other element type
 * for the XCUIElement that has keyboard focus.
 * @return the XCUIElement with keyboard focus or the XCUIApplication reference to the AUT
 */
- (XCUIElement *)firstResponderOrApplication;

@end
