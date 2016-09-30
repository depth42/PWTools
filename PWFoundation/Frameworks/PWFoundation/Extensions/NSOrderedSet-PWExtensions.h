//
//  NSOrderedSet-PWExtensions.h
//  PWFoundation
//
//  Created by Andreas Känner on 17.07.12.
//
//

NS_ASSUME_NONNULL_BEGIN

@interface NSOrderedSet<ObjectType> (PWExtensions)

- (BOOL)all:(BOOL (^)(ObjectType obj))block;
- (BOOL)any:(BOOL (^)(ObjectType obj))block;
- (nullable ObjectType)match:(BOOL (^)(ObjectType obj))block;
- (NSOrderedSet*)select:(BOOL (^)(ObjectType obj))block;
- (NSOrderedSet*)map:(id (^)(ObjectType obj))block;
- (NSOrderedSet*)mapWithoutNull:(nullable id (^)(ObjectType obj))block;
- (void)partitionIntoMatches:(NSOrderedSet* _Nonnull * _Nullable)outMatches
                      misses:(NSOrderedSet* _Nonnull * _Nullable)outMisses
                       block:(BOOL (^)(id obj))block;
- (NSOrderedSet<ObjectType>*)orderedSetWithMinusOrderedSet:(NSOrderedSet*)other;

@end

NS_ASSUME_NONNULL_END
