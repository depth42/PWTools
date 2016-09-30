//
//  PWBlockFormatter.m
//  PWFoundation
//
//  Created by Frank Illenberger on 10.03.10.
//
//

#import "PWBlockFormatter.h"

@implementation PWBlockFormatter

@synthesize toStringBlock       = toStringBlock_;
@synthesize toObjectValueBlock  = toObjectValueBlock_;
@synthesize preparationObject   = preparationObject_;
@synthesize preparationKeyPath  = preparationKeyPath_;

- (NSString*)stringForObjectValue:(id)anObject
{
    if(!toStringBlock_)
        [NSException raise:NSInternalInconsistencyException format:@"PWBlockFormatter has no toString block"];
    return toStringBlock_(self, anObject);
}

- (BOOL)getObjectValue:(id*)anObject 
             forString:(NSString*)string
      errorDescription:(NSString**)error
{
    if(!toObjectValueBlock_)
        [NSException raise:NSInternalInconsistencyException format:@"PWBlockFormatter has no toObjectValue block"];
    return toObjectValueBlock_(self, anObject, string, error);
}

- (id)objectForString:(NSString*)string
{
    id obj;
    [self getObjectValue:&obj forString:string errorDescription:NULL];
    return obj;
}

@end
