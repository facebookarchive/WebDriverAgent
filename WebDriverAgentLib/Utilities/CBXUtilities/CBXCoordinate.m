
#import "CBXCoordinate.h"

@interface CBXCoordinate()
@property (nonatomic, strong) id json;
@end

@implementation CBXCoordinate
- (CGPoint)cgpoint {
    return [CBXCoordinate pointFromCoordinateJSON:self.json];
}

- (float)x {
    return (float)self.cgpoint.x;
}

- (float)y {
    return (float)self.cgpoint.y;
}

+ (instancetype)fromRaw:(CGPoint)raw {
    return [self withJSON:@[ @(raw.x), @(raw.y) ]];
}

+ (instancetype)withJSON:(id)json {
    CBXCoordinate *coord = [self new];
    [self validatePointJSON:json];
    coord.json = json;
    return coord;
}

- (NSString *)description {
    CGPoint p = [self cgpoint];
    return [NSString stringWithFormat:@"(%f, %f)", p.x, p.y];
}

+ (CGPoint)pointFromCoordinateJSON:(id)json {
    [self validatePointJSON:json];
    
    if ([json isKindOfClass:[NSArray class]]) {
        return CGPointMake([json[0] floatValue],
                           [json[1] floatValue]);
    } else {
        return CGPointMake([json[@"x"] floatValue],
                           [json[@"y"] floatValue]);
    }
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[self class]]) { return NO; }
    CBXCoordinate *other = (CBXCoordinate *)object;
    return CGPointEqualToPoint(self.cgpoint, other.cgpoint);
}

+ (void)validatePointJSON:(id)json {
    if ([json isKindOfClass:[NSArray class]]) {
        if ([json count] < 2) {
            @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                           reason:[NSString stringWithFormat:
                                                          @"Error validating point JSON: expected [x, y], got %@",
                                                                             [CBXJSONUtils objToJSONString:json]]
                                         userInfo:nil];
        }
    } else {
        if (![json isKindOfClass:[NSDictionary class]]) {
            @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                           reason:[NSString stringWithFormat:
                                                          @"Error validating point JSON: expected dictionary, got %@",
                                                   NSStringFromClass([json class])]
                                         userInfo:nil];
        }
        if (!([[json allKeys] containsObject:@"x"] && [[json allKeys] containsObject:@"y"])) {
            @throw [NSException exceptionWithName:@"InvalidArgumentException"
                                           reason:[NSString stringWithFormat:
                                                          @"Error validating point JSON: expected { x : #, y : # }, got %@",
                                                          [CBXJSONUtils objToJSONString:json]]
                                         userInfo:nil];
        }
    }
}
@end
