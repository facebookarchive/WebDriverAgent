#import "CBXTextInputFirstResponderProvider.h"
#import "XCUIApplication.h"
#import "XCUIElement.h"
#import "CBXJSONUtils.h"

#import "FBApplication.h"
#import "FBSession.h"

@interface CBXTextInputFirstResponderProvider ()

@property(strong) NSPredicate *predicate;
@property(strong) NSArray<NSNumber *> *elementTypes;

@end

@implementation CBXTextInputFirstResponderProvider

- (instancetype)init {
    self = [super init];
    if (self) {
        _predicate = [NSPredicate predicateWithFormat:@"%K = %@",
                      @"hasKeyboardFocus",
                      @(YES)];
        // This is an optimization.  Querying all elements is for the one with keyboard
        // focus can be prohibitively expensive (tens of seconds).
        _elementTypes = @[@(XCUIElementTypeTextField),
                          @(XCUIElementTypeTextView),
                          @(XCUIElementTypeSecureTextField),
                          @(XCUIElementTypeOther)];
    }
    return self;
}

- (XCUIElement *)firstResponder {
    XCUIApplication *application = [FBSession activeSession].application;
    NSPredicate *predicate = self.predicate;
    XCUIElement *firstResponder = nil;
    for (NSNumber *number in self.elementTypes) {
        XCUIElementType type = (XCUIElementType)[number unsignedIntegerValue];
        XCUIElementQuery *firstResponderQuery = [application descendantsMatchingType:type];
        XCUIElementQuery *matching = [firstResponderQuery matchingPredicate:predicate];
        NSArray <XCUIElement *> *elements = [matching allElementsBoundByIndex];
        if ([elements count] == 1) {
            firstResponder = elements[0];
            NSLog(@"Element with keyboard focus has type %@",
                  [CBXJSONUtils stringForElementType:type]);
            break;
        }
    }
    if (!firstResponder) {
        NSLog(@"Could not find an element with keyboard focus");
    }

    return firstResponder;
}

- (XCUIElement *)firstResponderOrApplication {
    XCUIElement *firstResponder = [self firstResponder];
    if (!firstResponder) {
        firstResponder = [FBSession activeSession].application;
    }
    return firstResponder;
}

@end
