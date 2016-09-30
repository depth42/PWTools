//
//  PWOrderedDictionary.m
//  PWFoundation
//
//  Created by Kai on 2.6.10.
//
//

#import "PWOrderedDictionary.h"


@implementation PWMutableOrderedDictionary
{
    NSMutableDictionary*    dictionary_;    // invariant and always valid
    NSMutableArray*         orderedKeys_;   // invariant and always valid
}


- (instancetype) init
{
    if ((self = [super init]) != nil) {
        dictionary_  = [[NSMutableDictionary alloc] init];
        orderedKeys_ = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (instancetype) initWithCapacity:(NSUInteger)numItems
{
    if ((self = [super init]) != nil) {
        dictionary_  = [[NSMutableDictionary alloc] initWithCapacity:numItems];
        orderedKeys_ = [[NSMutableArray alloc] initWithCapacity:numItems];
    }
    
    return self;
}

#pragma mark NSDictionary Primitives

- (id)firstObject
{
    return self[self.firstKey];
}

- (id)lastObject
{
    return self[self.lastKey];
}

- (id)firstKey
{
    return orderedKeys_.firstObject;
}

- (id)lastKey
{
    return orderedKeys_.lastObject;
}

- (NSUInteger) count
{
    return dictionary_.count;
}

- (id) objectForKey:(id)aKey
{
    return dictionary_[aKey];
}

- (NSEnumerator*) keyEnumerator
{
    return [orderedKeys_ objectEnumerator];
}

#pragma mark NSMutableDictionary Primitives

- (void) setObject:(id)anObject forKey:(id)aKey
{
    if (dictionary_[aKey])
        [orderedKeys_ removeObjectAtIndex:[orderedKeys_ indexOfObject:aKey]];

    // The dictionary will copy the key anyway. To avoid making two copies of a mutable key, I copy it first and pass
    // the copy to both the dictionary and the array.
    aKey = [aKey copy];
    dictionary_[aKey] = anObject;
    [orderedKeys_ addObject:aKey];
}

- (void) removeObjectForKey:(id)aKey
{
    if (dictionary_[aKey]) {
        [orderedKeys_ removeObjectAtIndex:[orderedKeys_ indexOfObject:aKey]];
        [dictionary_  removeObjectForKey:aKey];
    }    
}

#pragma mark Non-Primitive Methods

// -enumerateKeysAndObjectsUsingBlock: is used by YAML writing, therefore I implement it directly for better efficiency.
- (void) enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL* stop))block
{
    [orderedKeys_ enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        block (obj, dictionary_[obj], stop);
    }];
}

@end
