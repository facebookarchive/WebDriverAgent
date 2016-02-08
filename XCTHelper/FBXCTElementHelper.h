#import <Foundation/Foundation.h>

@interface FBXCTElementHelper : NSObject
/*!
 * Types a string into the element. The element or a descendant must have keyboard focus; otherwise an
 * error is raised.
 *
 * This API discards any modifiers set in the current context by +performWithKeyModifiers:block: so that
 * it strictly interprets the provided text. To input keys with modifier flags, use  -typeKey:modifierFlags:.
 */
+ (BOOL)typeText:(NSString *)text error:(NSError **)error;
@end
