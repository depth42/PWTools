//
//  PWAsyncRUCache.h
//  PWFoundation
//
//  Created by Frank Illenberger on 08.10.15.
//  Copyright © 2015 ProjectWizards. All rights reserved.
//

#import <PWFoundation/PWDispatch.h>
#import <PWFoundation/PWEnumerable.h>

NS_ASSUME_NONNULL_BEGIN

// The removal handler is called asynchronously when an object is explicitly removed or implicitly evicted.
// The handler needs to call the passed-in response handler when it is done. Can be called on any queue.
// For implicit evictions, the handler can decide whether the object should be evicted or not, by
// adjusting the shouldRemove parameter. This is useful, if the object is currently
// in active use and its cache life should be prolonged.
// For non-optional removals, the shouldRemove parameter needs to be set to YES.
// ATTENTION: It is not allowed to call into the -objectForKey: ... -removeAllObjects: - evict: methods
//            before the responseHandler has been called.
typedef void(^PWLRUCacheRemovalResponseHandler)(BOOL shouldRemove);
typedef void(^PWLRUCacheRemovalHandler)(id key, id object, BOOL isOptional, PWLRUCacheRemovalResponseHandler responseHandler);

// Alternatively, as a convenience, the cache can be setup to call two individual handlers.
typedef void(^PWLRUCacheShouldEvictHandler)(id key, id object, PWLRUCacheRemovalResponseHandler responseHandler);
typedef void(^PWLRUCacheWillRemoveHandler)(id key, id object, PWDispatchBlock responseHandler);

typedef void(^PWLRUCacheObjectResponseBlock)(id object);
typedef void(^PWLRUCacheObjectCreationBlock)(id key, PWLRUCacheObjectResponseBlock responseBlock);

@protocol PWDispatchQueueing;

// Simple implementation of a least-recently-used cache with asynchronous interfaces.
// Automatically evicts objects when the system comes under memory pressure.
@interface PWAsyncLRUCache <KeyType, ObjectType> : NSObject

- (instancetype)init NS_UNAVAILABLE;

// Capacity needs to be > 0.
// Note that the count can grow larger than the given capacity if the evict handler refuses an object
// to be evicted.
- (instancetype)initWithCapacity:(NSUInteger)capacity
                  removalHandler:(PWLRUCacheRemovalHandler)removalHandler NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithCapacity:(NSUInteger)capacity
              shouldEvictHandler:(PWLRUCacheShouldEvictHandler)shouldEvictHandler
               willRemoveHandler:(PWLRUCacheWillRemoveHandler)willRemoveHandler;

- (void)disposeWithCompletionHandler:(PWDispatchBlock)completionHandler;

@property (nonatomic, readonly)         NSUInteger                  capacity;
@property (nonatomic, readonly, copy)   PWLRUCacheRemovalHandler    removalHandler;

- (void)setObject:(nullable ObjectType)object
           forKey:(KeyType)key;

- (void)objectForKey:(KeyType)key
   completionHandler:(void (^)(ObjectType _Nullable object))completionHandler;

- (void)objectForKey:(KeyType)key
       creationBlock:(nullable PWLRUCacheObjectCreationBlock)creationBlock
   completionHandler:(void (^)(ObjectType _Nullable object))completionHandler;

- (void)removeAllObjectsWithCompletionHandler:(PWDispatchBlock)completionHandler;

- (void)removeObjectForKeys:(NSArray<KeyType>*)keys
          completionHandler:(PWDispatchBlock)completionHandler;

- (void)allObjectsWithCompletionHandler:(void (^)(NSArray* allObjects))completionHandler;

// Is called when memory pressure occurs.
- (void)evictAsManyObjectsAsPossibleWithCompletionHandler:(PWDispatchBlock)completionHandler;

#pragma mark - For unit testing

@property (nonatomic, readonly)         NSUInteger              count;

- (nullable id)objectForKey:(KeyType)key;
- (nullable ObjectType)objectForKeyedSubscript:(KeyType)key;
- (void)setObject:(nullable ObjectType)obj forKeyedSubscript:(KeyType)key;

@end

NS_ASSUME_NONNULL_END
