//
//  NSNumber-PWExtensions.m
//  PWFoundation
//
//  Created by Andreas Känner on 28.05.09.
//
//

#import "NSNumber-PWExtensions.h"
#import "NSObject-PWExtensions.h"

@implementation NSNumber (PWExtensions)

- (instancetype)initWithStringRepresentation:(NSString*)string error:(NSError**)outError
{
    if([string isEqual:@"0"])
        self = [self initWithInteger:0];
    else if(string.doubleValue)
        self = [self initWithDouble:string.doubleValue];
    else if([string hasPrefix:@"y"] || [string hasPrefix:@"t"]) 
        self = [self initWithBool:YES];
    else if([string hasPrefix:@"n"] || [string hasPrefix:@"f"])
        self = [self initWithBool:NO];
    else return nil;
    return self;
}

// Override from NSObject-PWExtensions
- (BOOL) isEqualFuzzy:(id)obj
{
    if (![obj isKindOfClass:NSNumber.class])
        return NO;
    
    __unsafe_unretained NSNumber* n2 = obj;

    // Make sure only floating point types are compared using .doubleValue. Integer types must be compared non-fuzzy,
    // especially because they can exceed the available precision of double.
    const char* objCType1 = self.objCType;
    const char* objCType2 = n2.objCType;
    if (   strcmp (objCType1, @encode(double)) == 0 || strcmp (objCType1, @encode(float)) == 0
        || strcmp (objCType2, @encode(double)) == 0 || strcmp (objCType2, @encode(float)) == 0)
        return PWEqualDoubles (self.doubleValue, n2.doubleValue);
    
    return [self isEqualToNumber:n2];
}

#pragma mark encoding

- (NSNumber*)numberAsBool
{
    if(strcmp(self.objCType, @encode(BOOL)) == 0) // equals
        return self;
    
    // rebox else
    return self.boolValue ? @YES : @NO;
}

// convenience method to check on if type is boolean.
//#BE_REVIEW_IOS8_@encode(BOOL)
// avoids different objCType issue on IOS/MACOS
//      OSX10_9:    @(YES).objCType=='c' @encode(BOOL)=='c'
//      IOS:        @(YES).objCType=='c' @encode(BOOL)=='B'
// so on IOS we assume 'B' and 'c' to represent a BOOL value
- (BOOL)isObjCTypeBool
{
#if UXTARGET_IOS
    return (strcmp(self.objCType, @encode(BOOL)) == 0) || (strcmp(self.objCType, @encode(char)) == 0);
#else
    return (strcmp(self.objCType, @encode(BOOL)) == 0);
#endif
}

- (PWInteger)pwintegerValue
{
    return (PWInteger)self.integerValue;
}

- (PWUInteger)pwunsignedIntegerValue
{
    return (PWUInteger)self.unsignedIntegerValue;
}

@end
