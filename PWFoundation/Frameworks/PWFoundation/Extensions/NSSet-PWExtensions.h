//
//  NSSet-PWExtensions.h
//  PWFoundation
//
//  Created by Andreas Känner on 31.03.09.
//
//

#import <PWFoundation/PWEnumerable.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSSet<ObjectType> (PWExtensions)

// Note: returns [enumerable copy] if enumerable is of class NSSet.
+ (NSSet*) setWithEnumerable:(nullable NSObject<PWEnumerable>*)enumerable;

- (NSSet<ObjectType>*)setMinusSet:(NSSet*)minusSet;
- (NSSet<ObjectType>*)setByRemovingObject:(id)object;
- (NSSet<ObjectType>*)setByIntersectingSet:(NSSet*)intersectingSet;
- (NSUInteger)countIntersectionWithSet:(NSSet*)intersectingSet;

// Parameters can be nil. Returns empty set if both are nil.
+ (NSSet*)unionOfSet:(NSSet*)set1 andSet:(NSSet*)set2;

- (BOOL)all:(BOOL (^)(ObjectType obj))block;
- (BOOL)any:(BOOL (^)(ObjectType obj))block;
- (nullable ObjectType)match:(BOOL (^)(ObjectType obj))block;
- (NSUInteger)count:(BOOL (^)(ObjectType obj))block;
- (nullable NSSet<ObjectType>*)select:(BOOL (^)(ObjectType obj))block;
- (void)partitionIntoMatches:(NSSet* _Nullable* _Nonnull)outMatches
                      misses:(NSSet* _Nullable* _Nonnull)outMisses
                       block:(BOOL (^)(id obj))block;

// Returns copy of self if no changes. Elements mapped to nil are removed.
- (NSSet*)map:(id (^)(ObjectType obj))block;

// Forwards to -map:
- (NSSet*)mapWithoutNull:(nullable id (^)(ObjectType obj))block;

// Returns the set itself if it contains objects or nil if it is empty.
@property (nonatomic, readonly, copy) NSSet * _Nullable nilIfEmpty;

@end

NS_ASSUME_NONNULL_END
