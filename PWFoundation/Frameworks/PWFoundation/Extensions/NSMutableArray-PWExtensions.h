//
//  NSMutableArray-PWExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 16.10.06.
//
//

@class PWSortDescriptor;

@interface NSMutableArray<ObjectType> (PWExtensions)

// Returns a sorted copy of the receiver. If available, the selector compare:locale:
// is performed on the objects in the receiver, compare: otherwise
- (void)sortUsingDescriptors:(NSArray<PWSortDescriptor*>*)sortDescriptors
                      locale:(NSLocale*)locale
                     mapping:(id (^)(ObjectType obj))mapping;    // if specified, all objects are applied to the mapping block and the sortDescriptors are applied to its result

- (void)push:(ObjectType)object;
@property (nonatomic, readonly, strong) ObjectType pop;
- (void)filter:(BOOL (^)(ObjectType obj))block;

// If nextObject is not found or nil the object is inserted at the end of the array.
- (void)insertObject:(ObjectType)anObject beforeObject:(ObjectType)nextObject;

- (void) addObjectIfNotNil:(ObjectType)object;

@end
