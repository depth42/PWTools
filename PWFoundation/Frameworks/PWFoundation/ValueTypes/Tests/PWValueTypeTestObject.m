//
//  PWValueTypeTestObject.m
//  PWFoundation
//
//  Created by Frank Illenberger on 09.11.10.
//
//

#import "PWValueTypeTestObject.h"
#import "PWValueTypes.h"

@implementation PWValueTypeTestObject

@synthesize value           = value_;
@synthesize fallbackValue   = fallbackValue_;

+ (PWValueType*)valueValueType
{
    return [[PWCurrencyValueType alloc] initWithFallbackKeyPath:@"fallbackValue"
                                              presetValuesBlock:nil];
    
}

+ (PWValueType*)fallbackValueValueType
{
    return [PWCurrencyValueType valueType];
}

@end
