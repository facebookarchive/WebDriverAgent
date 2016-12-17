

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>

@interface CBXJSONUtils : NSObject
+ (NSString *)objToJSONString:(id)objcJsonObject;
/**
 Mapping of a string to an XCUIElementType enum value. E.g.,
 "scrollview" => XCUIElementTypeScrollView
 
 Note the mapping is case-insensitive.
 @param typeString human-readable version of element type
 @return XCUIElementType or -1 if not found.
 */
+ (XCUIElementType)elementTypeForString:(NSString *)typeString;

/**
 Inverse of elementTypeForString:
 Maps an XCUIElementType to a human-readable string.
 @param type XCUIElementType
 @return Human-readable string version of the XCUIElementType or `nil` if not found.
 */
+ (NSString *)stringForElementType:(XCUIElementType)type;
@end

@interface NSArray(CBXExtensions)
- (NSString *)pretty;
@end

@interface NSDictionary(CBXExtensions)
- (NSString *)pretty;
- (BOOL)hasKey:(NSString *)key;
@end
