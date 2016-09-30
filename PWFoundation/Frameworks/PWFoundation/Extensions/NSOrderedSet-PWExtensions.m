//
//  NSOrderedSet-PWExtensions.m
//  PWFoundation
//
//  Created by Andreas Känner on 17.07.12.
//
//

#import "NSOrderedSet-PWExtensions.h"

@implementation NSOrderedSet (PWExtensions)

- (BOOL)all:(BOOL (^)(id))block
{
    NSParameterAssert(block);
    for (id obj in self)
        if(!block(obj))
            return NO;
    return YES;  // Vacuous truth http://en.wikipedia.org/wiki/Vacuous_truth#Vacuous_truths_in_mathematics
}

- (BOOL)any:(BOOL (^)(id))block
{
    NSParameterAssert(block);
    for (id obj in self)
        if(block(obj))
            return YES;
    return NO;
}

- (nullable id)match:(BOOL (^)(id))block
{
    NSParameterAssert(block);
    for (id obj in self)
        if (block(obj))
            return obj;
    return nil;
}

- (NSOrderedSet*)select:(BOOL (^)(id))block
{
    NSParameterAssert(block);
    NSMutableOrderedSet* new = [NSMutableOrderedSet orderedSet];
    for (id obj in self)
        if (block(obj))
            [new addObject:obj];
    return [new copy];
}

- (NSOrderedSet*)map:(id (^)(id))block
{
    NSParameterAssert(block);
    __block NSMutableOrderedSet* new;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        id newObj = block(obj);
        if (!new) {
            if (newObj == obj)
                return;
            new = [NSMutableOrderedSet orderedSetWithCapacity:self.count];
            for (NSUInteger i = 0; i < idx; ++i)
                [new addObject:self[i]];
        }
        [new addObject:newObj ? newObj : [NSNull null]];
    }];
    return new ? new : [self copy];
}

- (NSOrderedSet*)mapWithoutNull:(nullable id (^)(id))block
{
    NSParameterAssert(block);
    __block NSMutableOrderedSet* new;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        id newObj = block(obj);
        if (!new) {
            if (newObj == obj)
                return;
            new = [NSMutableOrderedSet orderedSetWithCapacity:self.count];
            for (NSUInteger i = 0; i < idx; ++i)
                [new addObject:self[i]];
        }
        if (newObj)
            [new addObject:newObj];
    }];
    return new ? new : [self copy];
}

- (void)partitionIntoMatches:(NSOrderedSet**)outMatches
                      misses:(NSOrderedSet**)outMisses
                       block:(BOOL (^)(id obj))block
{
    NSParameterAssert(block);
    NSMutableOrderedSet* matches = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet* misses  = [NSMutableOrderedSet orderedSet];
    for (id obj in self)
    {
        if (block(obj))
            [matches addObject:obj];
        else
            [misses addObject:obj];
    }
    if(outMatches)
        *outMatches = [matches copy];
    if(outMisses)
        *outMisses = [misses copy];
}

- (NSOrderedSet*)orderedSetWithMinusOrderedSet:(NSOrderedSet*)other
{
    NSMutableOrderedSet* result = [NSMutableOrderedSet orderedSetWithOrderedSet:self];
    [result minusOrderedSet:other];
    return result;
}

#pragma mark PWEnumerable

- (NSUInteger) elementCount
{
    return self.count;
}

- (NSSet*) asSet
{
    return self.set;
}

@end
