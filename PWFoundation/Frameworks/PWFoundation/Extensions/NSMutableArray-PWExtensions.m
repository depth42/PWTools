//
//  NSMutableArray-PWExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 16.10.06.
//
//

#import "NSMutableArray-PWExtensions.h"
#import "NSArray-PWExtensions.h"

@implementation NSMutableArray (PWExtensions)

- (void)sortUsingDescriptors:(NSArray*)sortDescriptors       // PWSortDescriptor
                      locale:(NSLocale*)locale
                     mapping:(id (^)(id))mapping
{
    if(sortDescriptors.count == 0)
        return;
    return [self sortWithOptions:NSSortStable usingComparator:^NSComparisonResult(id o1, id o2) {
        return [NSArray compareObject:o1
                           withObject:o2
                     usingDescriptors:sortDescriptors
                               locale:locale
                              mapping:mapping];
    }];
}

- (void)push:(id)object
{
    [self addObject:object];
}

- (id)pop
{
    id result = nil;
    if(self.count > 0)
    {
       result = self[self.count-1];
       [self removeLastObject];
    }
    return result;
}

- (void)filter:(BOOL (^)(id))block 
{
    NSMutableIndexSet* deleteIndexes = [NSMutableIndexSet indexSet];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (!block(obj)) 
            [deleteIndexes addIndex:idx];
    }];
    [self removeObjectsAtIndexes:deleteIndexes];
}

- (void)insertObject:(id)anObject beforeObject:(id)nextObject
{
    NSUInteger index = [self indexOfObject:nextObject];
    if(index == NSNotFound)
        [self addObject:anObject];
    else 
        [self insertObject:anObject atIndex:index];
}

- (void) addObjectIfNotNil:(id)object
{
    if(object != nil)
        [self addObject:object];
}

@end
