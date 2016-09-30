//
//  NSSet-PWExtensions.m
//  PWFoundation
//
//  Created by Andreas Känner on 31.03.09.
//
//

#import "NSSet-PWExtensions.h"
#import "NSObject-PWExtensions.h"


NS_ASSUME_NONNULL_BEGIN

@implementation NSSet (PWExtensions)

+ (NSSet*) setWithEnumerable:(nullable NSObject<PWEnumerable>*)enumerable
{
    if ([enumerable isKindOfClass:NSSet.class])
        return [enumerable copy];
    
    NSUInteger count = enumerable.elementCount;
    if (count == 0)
        return [NSSet set];

    NSMutableSet* set = [NSMutableSet setWithCapacity:count];
    for (id object in enumerable)
        [set addObject:object];
    return set;
}

- (NSSet*)setMinusSet:(NSSet*)minusSet
{
    // Kai, 22.1.16: removed nil return if result is empty to match the nullability specifier and standard behavior.
    // Also added parameter assert according to nullability specifier.
    NSParameterAssert (minusSet);
    NSMutableSet* set = [self mutableCopy];
    [set minusSet:minusSet];
    return set;
}

- (NSSet*)setByRemovingObject:(id)object
{
    NSMutableSet* set = [self mutableCopy];
    [set removeObject:object];
    return set;
}

- (NSSet*)setByIntersectingSet:(NSSet*)intersectingSet
{
    NSMutableSet* set = [self mutableCopy];
    [set intersectSet:intersectingSet];
    return set;
}

- (NSUInteger)countIntersectionWithSet:(NSSet*)intersectingSet
{
    return [intersectingSet count:^BOOL (id obj) {  // leverages messaging to nil
        return [self containsObject:obj];
    }];
}

+ (NSSet*)unionOfSet:(NSSet*)set1 andSet:(NSSet*)set2
{
    if (set1.count == 0)
        return set2 ? set2 : [NSSet set];
    
    if (set2.count == 0)
        return set1;
    
    NSMutableSet* result = [set1 mutableCopy];
    [result unionSet:set2];
    return result;
}

#pragma mark Blocks

- (BOOL)all:(BOOL (^)(id))block 
{
    NSParameterAssert (block);

    BOOL truth = YES;    // Vacuous truth http://en.wikipedia.org/wiki/Vacuous_truth#Vacuous_truths_in_mathematics
    for (id obj in self)
        truth = truth && block(obj);
    return truth;
}

- (BOOL)any:(BOOL (^)(id))block 
{
    NSParameterAssert (block);

    for (id obj in self)
        if(block(obj))
            return YES;
    return NO;
}

- (nullable id)match:(BOOL (^)(id))block
{
    NSParameterAssert (block);

    for (id obj in self)
        if (block(obj)) 
            return obj;
    return nil;
}

- (NSUInteger)count:(BOOL (^)(id obj))block
{
    NSParameterAssert (block);

    NSUInteger count = 0;
    for (id obj in self)
        if (block(obj)) 
            ++count;
    return count;
}

- (nullable NSSet*)select:(BOOL (^)(id))block
{
    NSParameterAssert (block);

    // OPT: could return [self copy] if everything is selected.
    NSMutableSet* new;
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
    NSParameterAssert(block);
    
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
    if(outMatches)
        *outMatches = matches;
    if(outMisses)
        *outMisses = misses;
}

- (NSSet*)map:(id (^)(id))block
{
    NSParameterAssert (block);
    
    if (self.count == 0)
        return [self copy];

    // Because a set can not be copied "up to an index" without assuming that enumerations of a given set always return
    // the elements in the same order, a new set is always build and thrown away at the end if nothing changes.
    // Note: the assumption above about enumeration order is probably safe, but not documented.
    NSMutableSet* newSet = [NSMutableSet setWithCapacity:self.count];
    __block BOOL anyChange = NO;
    for (id obj in self) {
        id newObj = block (obj);
        if (newObj != obj)
            anyChange = YES;
        if (newObj)
            [newSet addObject:newObj];
    }
    return anyChange ? newSet : [self copy];
}

- (NSSet*)mapWithoutNull:(nullable id (^)(id))block
{
    return [self map:block];
}

- (nullable NSSet*)nilIfEmpty
{
    return self.count > 0 ? self : nil;
}

#pragma mark PWEnumerable

- (NSUInteger) elementCount
{
    return self.count;
}

- (NSSet*) asSet
{
    return self;
}

#pragma mark Debugging Support

// This -description replacement uses -shortDescription for the element descriptions. Useful for containers
// with NSManagedObjects, which have a very verbose description.
- (NSString*) description
{
    NSMutableString* desc = [NSMutableString stringWithFormat:@"%@ (%p) {\n", self.className, self];
    BOOL first = YES;
    for (id element in self) {
        if (!first)
            [desc appendString:@",\n"];
        [desc appendString:[element shortDescription]];
        first = NO;
    }
    [desc appendString:@"\n}"];
    return desc;
}

@end

NS_ASSUME_NONNULL_END
