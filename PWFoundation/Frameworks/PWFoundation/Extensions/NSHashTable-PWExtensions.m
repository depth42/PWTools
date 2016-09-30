//
//  NSHashTable-PWExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 25.01.14.
//
//

#import "NSHashTable-PWExtensions.h"

@implementation NSHashTable (PWExtensions)

- (BOOL)all:(BOOL (^)(id))block
{
    BOOL truth = YES;
    for (id obj in self)
        truth = truth && block(obj);
    return truth;
}

- (BOOL)any:(BOOL (^)(id))block
{
    for (id obj in self)
        if(block(obj))
            return YES;
    return NO;
}

- (nullable id)match:(BOOL (^)(id))block
{
    for (id obj in self)
        if (block(obj))
            return obj;
    return nil;
}

- (NSUInteger)count:(BOOL (^)(id obj))block
{
    NSUInteger count = 0;
    for (id obj in self)
        if (block(obj))
            ++count;
    return count;
}

- (nullable NSSet*)select:(BOOL (^)(id))block
{
    // OPT: could return [self copy] if everything is selected.
    NSMutableSet* new ;
    for (id obj in self)
    {
        if (block(obj))
        {
            if(!new)
                new = [NSMutableSet set];
            [new addObject:obj];
        }
    }
    return new;
}

- (void)partitionIntoMatches:(NSSet**)outMatches
                      misses:(NSSet**)outMisses
                       block:(BOOL (^)(id obj))block
{
    NSParameterAssert (outMatches);
    NSParameterAssert (outMisses);

    NSMutableSet* matches;
    NSMutableSet* misses;
    for (id obj in self) {
        if (block(obj)) {
            if (!matches)
                matches = [NSMutableSet set];
            [matches addObject:obj];
        } else {
            if (!misses)
                misses = [NSMutableSet set];
            [misses addObject:obj];
        }
    }
    *outMatches = matches;
    *outMisses  = misses;
}

- (NSSet*)map:(id (^)(id))block
{
    NSMutableSet* new = [NSMutableSet setWithCapacity:self.count];
    for (id obj in self)
    {
        id newObj = block(obj);
        if(newObj)
            [new addObject:newObj];
    }
    return new;
}

- (NSSet*)mapWithoutNull:(id (^)(id))block
{
    return [self map:block];
}

- (NSUInteger)elementCount
{
    return self.count;
}
@end
