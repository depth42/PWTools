//
//  NSArray-PWExtensions.h
//  Merlin
//
//  Created by Frank Illenberger on Sat Apr 10 2004.
//
//

#import <PWFoundation/PWEnumerable.h>

NS_ASSUME_NONNULL_BEGIN

@class PWSortDescriptor;

// AK@FI: I think this is not the right file for the marker. Where to put it in instead?
extern id const PWMultipleValuesMarker;

typedef void (^PWAsynchronousEnumerationObjectCompletionHandler) (BOOL stop, NSError* _Nullable error);

@interface NSArray<ObjectType> (PWExtensions) <PWEnumerable>

// Returns [enumerable copy] if enumerable is an array, else creates a new array.
+ (instancetype) arrayWithEnumerable:(nullable id<PWEnumerable>)enumerable;

- (BOOL)containsObjects:(NSArray<ObjectType> *)objects;
- (BOOL)containsObjectsOfClass:(Class)aClass;
- (BOOL)containsObjectsOfClassWithName:(NSString *)className;
- (BOOL)containsObjectIdenticalTo:(id)anObject;
- (NSArray<ObjectType>*)arrayFilteredWithClassName:(NSString *)className;
@property (nonatomic, readonly, copy) NSMutableArray<ObjectType> * _Nonnull deepMutableCopy;
@property (nonatomic, readonly, copy) NSArray<ObjectType> * _Nonnull allObjects;
- (nullable ObjectType)objectBehindFirstOccurrenceOfObject:(id)object;
@property (nonatomic, readonly) BOOL containsMixedObjects;

- (BOOL)all:(BOOL (^)(ObjectType obj))block;
- (BOOL)any:(BOOL (^)(ObjectType obj))block;
- (nullable ObjectType)match:(BOOL (^)(ObjectType obj))block;
- (NSArray<ObjectType>*)select:(BOOL (^)(ObjectType obj))block;
- (void)partitionIntoMatches:(NSArray* _Nonnull* _Nullable)outMatches
                      misses:(NSArray* _Nonnull* _Nullable)outMisses
                       block:(BOOL (^)(ObjectType obj))block;
- (NSArray*)map:(id (^)(ObjectType obj))block;          // returns copy of self if no changes
- (NSArray*)mapWithoutNull:(nullable id (^)(ObjectType obj))block;   // returns copy of self if no changes

// Calls 'block' for each object in the receiver in turn and waits each time for 'objectCompletionHandler' to be
// called before continuing with the next object.
// Finally calls 'completionHandler', passing NO for 'didFinish' if the enumeration has been stopped by calling
// an objectCompletionHandler with 'stop' == YES, error contains the last error returned by the objectComepletionHandler.
// Note: whenever 'objectCompletionHandler' is called synchronously by 'block', one stack frame is added in release build.
- (void) asynchronouslyEnumerateObjectsUsingBlock:(void(^)(ObjectType object,
                                                           PWAsynchronousEnumerationObjectCompletionHandler objectCompletionHandler))block
                                completionHandler:(void(^)(BOOL didFinish, NSError* _Nullable lastError))completionHandler;

// calculates diff between self and given changeArray
- (void)splitWithChangeArray:(nullable NSArray*)changeArray resultBlock:(void(^)(NSArray* addedObjects, NSArray* removedObjects))block;

// Always returns valid array, which may be empty.
// nil return value from 'generator' is saved as NSNull in the array.
+ (NSArray<ObjectType>*)arrayWithCount:(NSUInteger)count generator:(id(^)(NSUInteger index, BOOL* stop))generator;

- (NSArray<ObjectType>*)subarrayFromIndex:(NSUInteger)startIndex;
- (NSArray<ObjectType>*)subarrayOrNilFromIndex:(NSUInteger)startIndex;

- (NSArray<ObjectType>*)subarrayToIndex:(NSUInteger)endIndex;
- (NSArray<ObjectType>*)subarrayOrNilToIndex:(NSUInteger)endIndex;

// may be used to compare each with each without duplicates and permutations
// e.g. an array with ABCA will call back with the tuples: AB, AC, BC only.
// proper usage of this method assumes that it is more efficient to work with the reduced tuples
//      at the cost of internally storing already compared pairs involving memory and lookup overhead
- (void)enumerateCombinationPairsUsingBlock:(void (^)(ObjectType obj1, ObjectType obj2, BOOL *stop))block;

// Returns a sorted copy of the receiver. If available, the selector compare:locale:
// is performed on the objects in the receiver, compare: otherwise
- (NSArray<ObjectType>*)sortedArrayUsingDescriptors:(nullable NSArray<PWSortDescriptor*>*)sortDescriptors
                                             locale:(nullable NSLocale*)locale
                                            mapping:(id (^_Nullable)(ObjectType))mapping;    // if specified, all objects are applied to the mapping block and the sortDescriptors are applied to its result

+ (NSComparisonResult)compareObject:(ObjectType)o1
                         withObject:(ObjectType)o2
                   usingDescriptors:(nullable NSArray<PWSortDescriptor*>*)sortDescriptors
                             locale:(nullable NSLocale*)locale
                            mapping:(id (^_Nullable)(ObjectType))mapping;

@property (nonatomic, readonly, copy) NSArray<ObjectType> * _Nonnull reversedArray;

// Returns YES if objects at each index from both arrays have the same identity or both arrays are empty.
- (BOOL) isContentIdenticalToContentOfArray:(NSArray*)otherArray;

- (NSArray<ObjectType>*)arrayByRemovingLastObject;
- (NSArray<ObjectType>*)arrayByRemovingObject:(id)object;
- (NSArray<ObjectType>*)arrayByRemovingObjectsInArray:(NSArray<ObjectType>*)other;

- (NSComparisonResult)compare:(NSArray*)otherArray;

// Returns the array itself if it contains objects or nil if it is empty.
@property (nonatomic, readonly, copy) NSArray * _Nullable nilIfEmpty;

@end

@interface NSArray (PWExtensionsStrings)

// short for componentsJoinedByString:@"". nil if receiver is empty.
@property (nonatomic, readonly, copy) NSString * _Nullable componentsJoined;

@end

// Returns YES if objects at each index from both arrays have the same identity, both arrays are empty or if both arrays are nil.
NS_INLINE BOOL PWIdenticalObjectsInArrays(NSArray* _Nullable firstArray, NSArray* _Nullable secondArray)
{
    return firstArray == secondArray || (secondArray && [firstArray isContentIdenticalToContentOfArray:secondArray]);
}

NS_INLINE NSArray* PWJoinedArrays(NSArray* _Nullable firstArray, NSArray* _Nullable secondArray)
{
    return firstArray && secondArray ? [firstArray arrayByAddingObjectsFromArray:secondArray] : firstArray ? firstArray : secondArray;
}

NS_INLINE NSArray* PWEmptyArrayForNil(NSArray* _Nullable array)
{
    return array ? array : @[];
}

NS_ASSUME_NONNULL_END
