//
//  NSHashTable-PWExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 25.01.14.
//
//

NS_ASSUME_NONNULL_BEGIN

@interface NSHashTable<ObjectType> (PWExtensions)

- (BOOL)all:(BOOL (^)(ObjectType))block;
- (BOOL)any:(BOOL (^)(ObjectType))block;
- (nullable id)match:(BOOL (^)(ObjectType))block;
- (NSUInteger)count:(BOOL (^)(ObjectType obj))block;
- (nullable NSSet<ObjectType>*)select:(BOOL (^)(ObjectType))block;

- (void)partitionIntoMatches:(NSSet* _Nonnull * _Nullable)outMatches
                      misses:(NSSet* _Nonnull * _Nullable)outMisses
                       block:(BOOL (^)(ObjectType obj))block;

- (NSSet*)map:(id (^)(ObjectType))block;

@end

NS_ASSUME_NONNULL_END
