//
//  NSArray-PWExtensions.m
//  Merlin
//
//  Created by Frank Illenberger on Sat Apr 10 2004.
//
//

#import "NSArray-PWExtensions.h"
#import "NSString-PWExtensions.h"
#import "NSObject-PWExtensions.h"
#import "NSNull-PWExtensions.h"
#import "PWSortDescriptor.h"
#import "PWEnumerable.h"


NS_ASSUME_NONNULL_BEGIN

id const PWMultipleValuesMarker = @"PWMultipleValuesMarker";

@implementation NSArray (PWExtensions)

+ (instancetype) arrayWithEnumerable:(nullable id<PWEnumerable>)enumerable
{
    if ([(id)enumerable isKindOfClass:NSArray.class])
        return [self arrayWithArray:(id)enumerable];    // TODO: double check this does not do unneeded coping
    
    NSMutableArray* result = [NSMutableArray arrayWithCapacity:enumerable.elementCount];
    for (id obj in enumerable)
        [result addObject:obj];
    return result;
}

- (NSArray*)arrayFilteredWithClassName:(NSString*)className
{
    Class class = NSClassFromString(className);
    NSMutableArray *result = [NSMutableArray array];
    for(id obj in self)
        if([obj isKindOfClass:class])
            [result addObject:obj];
    return result;
}

- (BOOL)containsObjects:(NSArray*)objects
{
    BOOL contains = YES;
    for(id obj in objects)
    {
        contains = [self containsObject:obj];
        if(!contains)
            break;
    }
    return contains;
}

- (BOOL)containsObjectsOfClass:(Class)aClass
{
    if(aClass)
        for(id obj in self)
            if([obj isKindOfClass:aClass])
                return YES;
    return NO;
}

- (BOOL)containsObjectsOfClassWithName:(NSString *)className
{
    PWParameterAssert(className);
    Class class = NSClassFromString(className);
    PWAssert(class != nil);
    return [self containsObjectsOfClass:class];
}

- (BOOL)containsObjectIdenticalTo:(id)anObject
{
    return [self indexOfObjectIdenticalTo:anObject] != NSNotFound;
}

- (NSMutableArray*)deepMutableCopy
{
    NSMutableArray *newArray = [[NSMutableArray alloc] initWithCapacity:self.count];
    for(id anObject in self)
    {
        if([anObject respondsToSelector:@selector(deepMutableCopy)]) 
            [newArray addObject:[anObject deepMutableCopy]];
        else if([anObject conformsToProtocol:@protocol(NSMutableCopying)]) 
            [newArray addObject:[anObject mutableCopy]];
        else if([anObject conformsToProtocol:@protocol(NSCopying)])
            [newArray addObject:[anObject copy]];
        else
            [newArray addObject:anObject];
    }
    
    return newArray;
}

+ (NSComparisonResult)compareObject:(id)o1
                         withObject:(id)o2
                   usingDescriptors:(nullable NSArray<PWSortDescriptor*>*)sortDescriptors
                             locale:(nullable NSLocale*)locale
                            mapping:(id (^_Nullable)(id))mapping
{
    NSParameterAssert(o1);
    NSParameterAssert(o2);
    NSParameterAssert(sortDescriptors);

    NSComparisonResult result = NSOrderedSame;
    if(mapping)
    {
        o1 = mapping(o1);
        o2 = mapping(o2);
    }
    for(PWSortDescriptor* desc in sortDescriptors) {
        id val1 = [desc valueForObject:o1];
        id val2 = [desc valueForObject:o2];
        // Note: We want nil values to be always sorted to the end, regardless of descriptor direction
        if(!val1 && val2)
            return NSOrderedDescending;
        else if(!val2 && val1)
            return NSOrderedAscending;
        else if(val2 && val1)
        {
            id cval1;
            id cval2;
            if(desc.ascending)
            {
                cval1 = val1;
                cval2 = val2;
            }
            else
            {
                cval1 = val2;
                cval2 = val1;
            }
            if([cval1 respondsToSelector:@selector(compare:locale:)])
                result = [cval1 compare:cval2 locale:locale];
            else if ([cval1 respondsToSelector:@selector(compare:)])
                result = [cval1 compare:cval2];
        }
        if(result != NSOrderedSame)
            break;
    }
    return result;    
}

- (NSComparisonResult)compare:(NSArray*)otherArray
{
    if(!otherArray)
        return NSOrderedDescending;

    NSUInteger count = self.count;
    NSUInteger otherCount = otherArray.count;
    NSUInteger minCount = MIN(count, otherCount);
    for(NSUInteger index=0; index<minCount; index++)
    {
        id value = self[index];
        id otherValue = otherArray[index];
        NSComparisonResult result = [value compare:otherValue];
        if(result != NSOrderedSame)
            return result;
    }
    if(count > otherCount)
        return NSOrderedDescending;
    else if(count == otherCount)
        return NSOrderedSame;
    else
        return NSOrderedAscending;
}

- (NSArray*)sortedArrayUsingDescriptors:(nullable NSArray<PWSortDescriptor*>*)sortDescriptors
                                 locale:(nullable NSLocale*)locale
                                mapping:(id (^_Nullable)(id))mapping
{
    if(sortDescriptors.count == 0)
        return [self copy];
    return [self sortedArrayUsingComparator:^NSComparisonResult(id o1, id o2) {
        return [NSArray compareObject:o1
                           withObject:o2
                     usingDescriptors:sortDescriptors
                               locale:locale
                              mapping:mapping];
    }];
}

- (NSArray *)allObjects
{
    return [self copy];
}

- (nullable id)objectBehindFirstOccurrenceOfObject:(id)object
{
    id result;
    NSUInteger index = [self indexOfObject:object];
    if(index != NSNotFound)
    {
        index++;
        if(index < self.count)
            result = self[index];
    }
    return result;
}

// Override from NSObject-PWExtensions
- (BOOL) isEqualFuzzy:(id)obj
{
    if (![obj isKindOfClass:NSArray.class])
        return NO;
    
    __unsafe_unretained NSArray* array2 = obj;
    NSUInteger count = self.count;
    if (count != array2.count)
        return NO;
    
    for (NSUInteger i = 0; i < count; ++i)
        if (![self[i] isEqualFuzzy:array2[i]])
            return NO;
    
    return YES;
}

- (nullable NSArray*)nilIfEmpty
{
    return self.count > 0 ? self : nil;
}

#pragma mark - Blocks
 
- (BOOL)all:(BOOL (^)(id))block 
{
    NSParameterAssert(block);
    for (id obj in self)
       if(!block(obj))
           return NO;
    return YES; // Vacuous truth http://en.wikipedia.org/wiki/Vacuous_truth#Vacuous_truths_in_mathematics
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
 
- (NSArray*)select:(BOOL (^)(id))block 
{
    NSParameterAssert(block);
    NSMutableArray* new = [NSMutableArray array];
    for (id obj in self)
        if (block(obj)) 
            [new addObject:obj];
    return new;
}
 
- (void)partitionIntoMatches:(NSArray**)outMatches
                      misses:(NSArray**)outMisses
                       block:(BOOL (^)(id obj))block
{
    NSParameterAssert(block);
    NSMutableArray* matches = [NSMutableArray array];
    NSMutableArray* misses  = [NSMutableArray array];
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
 
- (NSArray*)map:(id (^)(id))block 
{
    NSParameterAssert(block);
    __block NSMutableArray* new;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        id newObj = block(obj);
        if (!new) {
            if (newObj == obj)
                return;
            new = [NSMutableArray arrayWithCapacity:self.count];
            for (NSUInteger i = 0; i < idx; ++i)
                [new addObject:self[i]];
        }
        [new addObject:PWNullForNil (newObj)];
    }];
    return new ? new : [self copy];
}
 
- (NSArray*)mapWithoutNull:(nullable id (^)(id))block
{
    NSParameterAssert(block);
    __block NSMutableArray* new;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL* stop) {
        id newObj = block(obj);
        if (!new) {
            if (newObj == obj)
                return;
            new = [NSMutableArray arrayWithCapacity:self.count];
            for (NSUInteger i = 0; i < idx; ++i)
                [new addObject:self[i]];
        }
        if (newObj)
            [new addObject:newObj];
    }];
    return new ? new : [self copy];
}

- (void)splitWithChangeArray:(nullable NSArray*)changeArray resultBlock:(void(^)(NSArray* addedObjects, NSArray* removedObjects))block
{
    NSParameterAssert(block);
    
    NSMutableArray *previousObjects = [self mutableCopy];
    NSMutableArray *currentObjects = [changeArray mutableCopy];
    [currentObjects removeObjectsInArray:self];
    [previousObjects removeObjectsInArray:changeArray];
    NSArray *addedObjects = currentObjects;
    NSArray *removedObjects = previousObjects;
    
    if (addedObjects.count > 0 || removedObjects.count > 0)
        block(addedObjects, removedObjects);
}

+ (NSArray*)arrayWithCount:(NSUInteger)count generator:(id(^)(NSUInteger index, BOOL* stop))generator
{
    NSParameterAssert (generator);
    NSMutableArray* array = [NSMutableArray array];
    BOOL stop = NO;
    for (NSUInteger i = 0; i < count; ++i) {
        id obj = generator (i, &stop);
        if (stop)
            break;
        [array addObject:obj ? obj : [NSNull null]];
    }
    return array;
}

- (NSArray*)subarrayFromIndex:(NSUInteger)startIndex
{
    return [self subarrayWithRange:NSMakeRange (startIndex, self.count - startIndex)];
}

- (NSArray*)subarrayOrNilFromIndex:(NSUInteger)startIndex
{
    NSUInteger count = self.count;
    return (startIndex < count) ? [self subarrayWithRange:NSMakeRange (startIndex, count - startIndex)] : nil;
}

- (NSArray*)subarrayToIndex:(NSUInteger)endIndex
{
    return [self subarrayWithRange:NSMakeRange (0, endIndex)];
}

- (NSArray*)subarrayOrNilToIndex:(NSUInteger)endIndex
{
    return (endIndex > 0) ? [self subarrayWithRange:NSMakeRange (0, endIndex)] : nil;
}

- (void)enumerateCombinationPairsUsingBlock:(void (^)(id obj1, id obj2, BOOL *stop))block
{
    NSMapTable* compareMap = [NSMapTable strongToStrongObjectsMapTable];
    for (NSUInteger index1 = 0; index1 < self.count; index1++)
    {
        for (NSUInteger index2 = index1+1; index2 < self.count; index2++)
        {
            id obj1 = self[index1];
            id obj2 = self[index2];
            
            if ([obj1 isEqual:obj2])
                continue;
            
            // in a 2D map store which object already had been compared to what other
            {
                // skip if known tuple
                NSMutableSet* compared1 = [compareMap objectForKey:obj1];
                if ([compared1 containsObject:obj2])
                    continue;
                NSMutableSet* compared2 = [compareMap objectForKey:obj2];
                if ([compared2 containsObject:obj1])
                    continue;
                
                // store
                if (compared1 == nil)
                {
                    compared1 = [NSMutableSet setWithCapacity:self.count-1];
                    [compareMap setObject:compared1 forKey:obj1];
                }
                if (compared2 == nil)
                {
                    compared2 = [NSMutableSet setWithCapacity:self.count-1];
                    [compareMap setObject:compared2 forKey:obj2];
                }
                
                [compared1 addObject:obj2];
                [compared2 addObject:obj1];
            }
            
            BOOL stop = NO;
            block(obj1, obj2, &stop);
            
            if (stop) return;
        }
    }
}

- (NSArray*)reversedArray
{
    NSMutableArray* array = [NSMutableArray arrayWithCapacity:self.count];
    for (id element in self.reverseObjectEnumerator)
        [array addObject:element];
    return array;
}

- (BOOL) containsMixedObjects
{
    if(self.count > 1)
    {
        id value = self.firstObject;
        return [self any:^(id obj) {
            return (BOOL)!PWEqualObjects(value, obj);
        }];
    }
    return NO;    
}

- (void) asynchronouslyEnumerateObjectsUsingBlock:(void(^)(id object,
                                                           PWAsynchronousEnumerationObjectCompletionHandler objectCompletionHandler))block
                                completionHandler:(void(^)(BOOL didFinish, NSError* _Nullable lastError))completionHandler
{
    NSParameterAssert (block);
    NSParameterAssert (completionHandler);
    
    // Start with the first element.
    [self asynchronouslyVisitObjectAtIndex:0
                                 lastError:nil
                                usingBlock:block
                         completionHandler:completionHandler];
}

- (void) asynchronouslyVisitObjectAtIndex:(NSUInteger)index
                                lastError:(NSError* _Nullable)lastError
                               usingBlock:(void(^)(id object,
                                                   PWAsynchronousEnumerationObjectCompletionHandler objectCompletionHandler))block
                        completionHandler:(void(^)(BOOL didFinish, NSError* _Nullable lastError))completionHandler
{
    NSParameterAssert (block);
    NSParameterAssert (completionHandler);
    
    if (index >= self.count) {
        completionHandler (/*didFinish =*/YES, lastError);
        return;
    }
    
    block (self[index], ^(BOOL stop, NSError* error) {
        if (stop)
            completionHandler (/*didFinish =*/NO, error);
        else
            // Continue with the next element. Pass the latest error through.
            [self asynchronouslyVisitObjectAtIndex:index + 1
                                         lastError:error ? error : lastError
                                        usingBlock:block
                                 completionHandler:completionHandler];
    });
}

#pragma mark - PWEnumerable

- (NSUInteger) elementCount
{
    return self.count;
}

- (NSSet*) asSet
{
    return [NSSet setWithArray:self];
}

#pragma mark - Debugging Support

// This -description replacement uses -shortDescription for the element descriptions. Useful for containers
// with NSManagedObjects, which have a very verbose description.
- (NSString*) description
{
    NSMutableString* desc = [NSMutableString stringWithFormat:@"%@ (%p) (\n", self.className, self];
    BOOL first = YES;
    for (id element in self) {
        if (!first)
            [desc appendString:@",\n"];
        [desc appendString:[element shortDescription]];
        first = NO;
    }
    [desc appendString:@"\n)"];
    return desc;
}

- (NSString*) debugDescription
{
    NSMutableString* desc = [NSMutableString stringWithFormat:@"%@ (%p) (\n", self.className, self];
    BOOL first = YES;
    for (id element in self) {
        if (!first)
            [desc appendString:@",\n"];
        [desc appendString:[element shortDescription]];
        first = NO;
    }
    [desc appendString:@"\n)"];
    return desc;
}

- (BOOL) isContentIdenticalToContentOfArray:(NSArray*)otherArray
{
    if(otherArray.count != self.count)
        return NO;

    NSUInteger idx = 0;
    for(id iObj in self)
    {
        if(otherArray[idx] != iObj)
            return NO;
        idx++;
    }
    return YES;
}

- (NSArray*)arrayByRemovingObject:(id)object
{
    NSParameterAssert(object);
    return [self mapWithoutNull:^id(id iObject) {
        return ![iObject isEqual:object] ? iObject : nil;
    }];
}

- (NSArray*)arrayByRemovingObjectsInArray:(NSArray*)other
{
    NSParameterAssert(other);
    return [self select:^BOOL(id  _Nonnull obj) {
        return ![other containsObject:obj];
    }];
}

- (NSArray*)arrayByRemovingLastObject
{
    if (self.count == 1)
        return @[];
    return [self subarrayToIndex:self.count-1];
}

@end

#pragma mark

@implementation NSArray (PWExtensionsStrings)

- (nullable NSString*)componentsJoined
{
    NSUInteger count = self.count;
    switch (count) {
        case 0:
            return nil;
        case 1:
            return self.firstObject;
        case 2:
            return [(NSString*)self[0] stringByAppendingString:self[1]];
            
        default:
            break;
    }
    
    NSMutableString* workString = [NSMutableString new];
    for (NSUInteger index = 0; index < self.count; index++)
    {
        [workString appendString:self[index]];
    }
    return workString;
}

@end

NS_ASSUME_NONNULL_END
