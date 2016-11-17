//
//  PWLRUCache.h
//  PWFoundation
//
//  Created by Frank Illenberger on 08.10.15.
//  Copyright © 2015 ProjectWizards. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@class PWLRUCache;
@protocol PWDispatchQueueing;

@protocol PWLRUCacheDelegate <NSObject>
// Tis delegation can refuse to evict an object because it is long unused.
// This is useful, if the object is currently
// in active use and its cache life should be prolonged.
// The delegate is only called for evictions, not removals.
- (BOOL)cache:(PWLRUCache*)cache canEvictObject:(id)object;
- (void)cache:(PWLRUCache*)cache willRemoveObject:(id)object;
@end

// Simple implementation of a least-recently-used cache
@interface PWLRUCache <KeyType, ObjectType> : NSObject

- (instancetype)init NS_UNAVAILABLE;

// Capacity needs to be > 0.
// Note that the count can grow larger than the given capacity if the delegate refuses an object
// to be evicted.
// The receiver's method may only be called on the given dispatch queue.
// The same queue is used for asynchronously evicting objects when the system comes under memory pressure.
- (instancetype)initWithCapacity:(NSUInteger)capacity
                        delegate:(nullable id<PWLRUCacheDelegate>)delegate
                   dispatchQueue:(id <PWDispatchQueueing>)dispatchQueue NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly)         NSUInteger              capacity;
@property (nonatomic, readonly)         NSUInteger              count;
@property (nonatomic, readonly, weak)   id<PWLRUCacheDelegate>  delegate;
@property (nonatomic, readonly, strong) id<PWDispatchQueueing>  dispatchQueue;

- (void)setObject:(nullable ObjectType)object forKey:(KeyType)key;
- (nullable ObjectType)objectForKey:(KeyType)key;

- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType)key;

- (void)removeAllObjects;

// Is called when memory pressure occurs.
- (void)evictAsManyObjectsAsPossible;
@end


NS_ASSUME_NONNULL_END
