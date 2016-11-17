//
//  PWAsyncLRUCache.m
//  PWFoundation
//
//  Created by Frank Illenberger on 24.06.16.
//  Copyright © 2016 ProjectWizards. All rights reserved.
//

#import "PWAsyncLRUCache.h"
#import "NSArray-PWExtensions.h"
#import <unordered_map>
#import <list>

NS_ASSUME_NONNULL_BEGIN

struct Hash
{
    size_t operator() (id const& obj) const
    {
        return [obj hash];
    }
};

struct EqualTo
{
    bool operator() (id const& obj1, id const& obj2) const
    {
        return [obj1 isEqual:obj2];
    }
};

typedef std::pair<id, id> KeyObjectPair;
typedef std::list<KeyObjectPair> List;
typedef std::list<KeyObjectPair>::iterator ListIterator;

typedef void (^EnumerationObjectCompletionHandler) (BOOL eraseObjectFromList);

@implementation PWAsyncLRUCache
{
    List _leastRecentUsageList;
    std::unordered_map<__unsafe_unretained id, ListIterator, Hash, EqualTo> _map;
    PWDispatchMemoryPressureObserver* _memoryPressureObserver;
    PWDispatchQueue* _dispatchQueue;
    PWDispatchQueue* _callbackQueue;
}

- (instancetype)initWithCapacity:(NSUInteger)capacity
                  removalHandler:(PWLRUCacheRemovalHandler)removalHandler
{
    NSParameterAssert(capacity != NSNotFound && capacity > 0);
    NSParameterAssert(removalHandler);

    self = [super init];

    _capacity = capacity;
    _dispatchQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWAsyncLRUCache"];
    _callbackQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWAsyncLRUCache_callback"];
    _removalHandler = [removalHandler copy];
    [self createMemoryPressureObserver];

    return self;
}

- (instancetype)initWithCapacity:(NSUInteger)capacity
              shouldEvictHandler:(PWLRUCacheShouldEvictHandler)shouldEvictHandler
               willRemoveHandler:(PWLRUCacheWillRemoveHandler)willRemoveHandler
{
    NSParameterAssert(shouldEvictHandler);
    NSParameterAssert(willRemoveHandler);

    return [self initWithCapacity:capacity
                   removalHandler:^(id key,
                                    id object,
                                    BOOL isOptional,
                                    PWLRUCacheRemovalResponseHandler responseHandler)
            {
                if(isOptional)
                {
                    shouldEvictHandler(key, object, ^(BOOL shouldRemove) {
                        if(shouldRemove)
                        {
                            willRemoveHandler(key, object, ^{
                                responseHandler(/* shouldRemove */ YES);
                            });
                        }
                        else
                            responseHandler(/* shouldRemove */ NO);
                    });
                }
                else
                {
                    willRemoveHandler(key, object, ^{
                        responseHandler(/* shouldRemove */ YES);
                    });
                }
            }];
}

- (void)disposeWithCompletionHandler:(PWDispatchBlock)completionHandler
{
    NSParameterAssert(completionHandler);
    
    [_dispatchQueue asynchronouslyDispatchBlock:^{
        if(_removalHandler)
        {
            [_memoryPressureObserver cancel];
            [self removeAllObjectsWithCompletionHandler:^{
                _removalHandler = nil;
                completionHandler();
            }];
        }
        else
            completionHandler();
    }];
}

- (void)objectForKey:(id)key
       creationBlock:(nullable PWLRUCacheObjectCreationBlock)creationBlock
   completionHandler:(void (^)(id _Nullable object))completionHandler
{
    NSParameterAssert(completionHandler);

    [_dispatchQueue asynchronouslyDispatchBlock:^{
        auto match = _map.find(key);
        if (match == _map.end())
        {
            if(creationBlock)
            {
                // While we are creating a new object, no further modifications and requests to the cache
                // are allowed to avoid uniqueness races.
                [_dispatchQueue suspend];
                [_callbackQueue asynchronouslyDispatchBlock:^{
                    creationBlock(key, ^(id object) {
                        [_callbackQueue dynamicallyDispatchBlock:^{
                            [self _setObject:object forKey:key];
                            [_dispatchQueue resume];
                            completionHandler(/* object */ object);
                        }];
                    });
                }];
            }
            else
                completionHandler(/* object */ nil);
        }
        else
        {
            // Everytime an object is returned, move it to the front of the least recent usage list.
            _leastRecentUsageList.splice(_leastRecentUsageList.begin(), _leastRecentUsageList, match->second);
            completionHandler(match->second->second);
        }
    }];
}

- (void)objectForKey:(id)key
   completionHandler:(void (^)(id _Nullable object))completionHandler
{
     [self objectForKey:key
         creationBlock:nil
     completionHandler:completionHandler];
}

- (void)setObject:(nullable id)object forKey:(id)key
{
    NSParameterAssert(key);

    [_dispatchQueue asynchronouslyDispatchBlock:^{
        [self _removeObjectForKey:key
                completionHandler:^{
                    NSAssert(_dispatchQueue.isCurrentDispatchQueue || _callbackQueue.isCurrentDispatchQueue, nil);
                    if(object)
                    {
                        [self _setObject:object forKey:key];

                        if (_map.size() > _capacity)
                            [self removeLeastRecentlyUsedObject];
                    }
                }];
    }];
}


- (void)_removeObjectForKey:(id)key
         completionHandler:(PWDispatchBlock)completionHandler
{
    NSParameterAssert(completionHandler);
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);

    auto it = _map.find(key);
    if (it != _map.end())
    {
        [_dispatchQueue suspend];
        [_callbackQueue asynchronouslyDispatchBlock:^{
            NSCAssert(_removalHandler, @"cache has been disposed");
            _removalHandler(/* key */ it->second->first,
                            /* object */ it->second->second,
                            /* isOptional */ NO,
                            /* responseHandler */^(BOOL shouldRemove) {
                                [_callbackQueue dynamicallyDispatchBlock:^{
                                    // Note: It is correct to access the ivars on the removal queue
                                    //       because _dispatchQueue is suspended.
                                    NSCAssert(shouldRemove, nil);
                                    _leastRecentUsageList.erase(it->second);
                                    _map.erase(it);
                                    completionHandler();    // Note: It is intentional, that the completion handler gets called before resume
                                    [_dispatchQueue resume];
                                }];
                            });
        }];
    }
    else
        completionHandler();
}

- (void)removeObjectForKeys:(NSArray*)keys
          completionHandler:(PWDispatchBlock)completionHandler
{
    [_dispatchQueue asynchronouslyDispatchBlock:^{
        [_dispatchQueue suspend];
        [_callbackQueue asynchronouslyDispatchBlock:^{
            [keys asynchronouslyEnumerateObjectsUsingBlock:^(id iKey,
                                                             PWAsynchronousEnumerationObjectCompletionHandler objectCompletionHandler) {
                auto it = _map.find(iKey);
                if(it != _map.end())
                {
                    NSCAssert(_removalHandler, @"cache has been disposed");
                    _removalHandler(/* key */ it->second->first,
                                    /* object */ it->second->second,
                                    /* isOptional */ NO,
                                    /* responseHandler */^(BOOL shouldRemove) {
                                        [_callbackQueue dynamicallyDispatchBlock:^{
                                            // Note: It is correct to access the ivars on the removal queue
                                            //       because _dispatchQueue is suspended.
                                            NSCAssert(shouldRemove, nil);
                                            _leastRecentUsageList.erase(it->second);
                                            _map.erase(it);
                                            objectCompletionHandler(/* stop */ NO, /* error */nil);
                                        }];
                                    });
                }
                else
                    objectCompletionHandler(/* stop */ NO, /* error */nil);

            } completionHandler:^(BOOL didFinish, NSError * _Nullable lastError) {
                [_dispatchQueue resume];
                completionHandler();
            }];
        }];
    }];
}


- (void)_setObject:(id)object forKey:(id)key
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue || _callbackQueue.isCurrentDispatchQueue, nil);

    _leastRecentUsageList.push_front(KeyObjectPair(key, object));
    _map[key] = _leastRecentUsageList.begin();
}

- (void)allObjectsWithCompletionHandler:(void (^)(NSArray* allObjects))completionHandler
{
    [_dispatchQueue asynchronouslyDispatchBlock:^{
        NSMutableArray* objects = [NSMutableArray array];
        for(auto kv : _map)
            [objects addObject:kv.second->second];
        completionHandler(objects);
    }];
}

- (void)removeLeastRecentlyUsedObject
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue || _callbackQueue.isCurrentDispatchQueue, nil);

    if(_leastRecentUsageList.empty())
        return;

    auto last = _leastRecentUsageList.end();
    last--;

    // While we are asking the remove handler for permission to remove we need to put
    // pending and future requests to the cache on hold.
    [_dispatchQueue suspend];
    [_callbackQueue dynamicallyDispatchBlock:^{
        NSCAssert(_removalHandler, @"cache has been disposed");
        _removalHandler(/* key */ last->first,
                        /* object */ last->second,
                        /* isOptional */ YES,
                        /* responseHandler */^(BOOL shouldRemove) {
                            [_callbackQueue dynamicallyDispatchBlock:^{
                                // Note: It is correct to access the ivars on the removal queue
                                //       because _dispatchQueue is suspended.
                                if(shouldRemove)
                                {
                                    _map.erase(last->first);
                                    _leastRecentUsageList.pop_back();
                                }
                                [_dispatchQueue resume];
                            }];
                        });
    }];
}

- (void)removeAllObjectsWithCompletionHandler:(PWDispatchBlock)completionHandler
{
    NSParameterAssert(completionHandler);

    [_dispatchQueue asynchronouslyDispatchBlock:^{
        [_dispatchQueue suspend];
        [self asynchronouslyEnumerateList:_leastRecentUsageList
                                  onQueue:_callbackQueue
                               usingBlock:^(id iKey,
                                            id iObject,
                                            EnumerationObjectCompletionHandler objectCompletionHandler) {
                                   NSCAssert(_callbackQueue.isCurrentDispatchQueue, nil);
                                   NSCAssert(_removalHandler, @"cache has been disposed");
                                   _removalHandler(iKey, iObject,
                                                   /* isOptional */ NO,
                                                   /* responseHandler */^(BOOL shouldRemove) {
                                                       NSCAssert(shouldRemove, nil);
                                                       objectCompletionHandler(/* eraseObjectFromList */ NO);
                                                   });

                               } completionHandler:^{
                                   NSCAssert(_callbackQueue.isCurrentDispatchQueue, nil);
                                   // Note: It is correct to access the ivars on the removal queue
                                   //       because _dispatchQueue is suspended.
                                   _map.clear();
                                   _leastRecentUsageList.clear();
                                   [_dispatchQueue resume];
                                   completionHandler();
                               }];
    }];
}


- (void)evictAsManyObjectsAsPossibleWithCompletionHandler:(PWDispatchBlock)completionHandler
{
    [_dispatchQueue asynchronouslyDispatchBlock:^{
        [_dispatchQueue suspend];
        [self asynchronouslyEnumerateList:_leastRecentUsageList
                                  onQueue:_callbackQueue
                               usingBlock:^(id iKey,
                                            id iObject,
                                            EnumerationObjectCompletionHandler objectCompletionHandler) {
                                   NSCAssert(_callbackQueue.isCurrentDispatchQueue, nil);
                                   NSCAssert(_removalHandler, @"cache has been disposed");
                                   _removalHandler(iKey, iObject,
                                                   /* isOptional */ YES,
                                                   /* responseHandler */^(BOOL shouldRemove) {
                                                       [_callbackQueue dynamicallyDispatchBlock:^{
                                                           // Note: It is correct to access the ivars on the removal queue
                                                           //       because _dispatchQueue is suspended.
                                                           if(shouldRemove)
                                                               _map.erase(iKey);
                                                           objectCompletionHandler(/* eraseObjectFromList */ shouldRemove);
                                                       }];
                                                   });

                               } completionHandler:^{
                                   NSCAssert(_callbackQueue.isCurrentDispatchQueue, nil);
                                   [_dispatchQueue resume];
                                   completionHandler();
                               }];
    }];
}

- (void) asynchronouslyEnumerateList:(List&)list
                             onQueue:(PWDispatchQueue*)queue
                          usingBlock:(void(^)(id iKey,
                                              id iObject,
                                              EnumerationObjectCompletionHandler objectCompletionHandler))block
                   completionHandler:(PWDispatchBlock)completionHandler
{
    NSParameterAssert (block);
    NSParameterAssert (queue);
    NSParameterAssert (completionHandler);

    // Start with the first element.
    [self asynchronouslyVisitObject:list.begin()
                             ofList:list
                            onQueue:queue
                         usingBlock:block
                  completionHandler:completionHandler];
}

- (void) asynchronouslyVisitObject:(ListIterator)objectIt
                            ofList:(List&)list
                           onQueue:(PWDispatchQueue*)queue
                        usingBlock:(void(^)(id iKey,
                                            id iObject,
                                            EnumerationObjectCompletionHandler objectCompletionHandler))block
                 completionHandler:(PWDispatchBlock)completionHandler
{
    NSParameterAssert (block);
    NSParameterAssert (completionHandler);

    [queue asynchronouslyDispatchBlock:^{
        if (objectIt == list.end()) {
            completionHandler ();
            return;
        }
        block (/* iKey */ objectIt->first,
               /* iObject */ objectIt->second,
               /* objectCompletionHandler */ ^(BOOL eraseObjectFromList)
               {
                   if(eraseObjectFromList)
                   {
                       [self asynchronouslyVisitObject:_leastRecentUsageList.erase(objectIt)
                                                ofList:list
                                               onQueue:queue
                                            usingBlock:block
                                     completionHandler:completionHandler];
                   }
                   else
                   {
                       ListIterator nextObjectIt = objectIt;
                       ++nextObjectIt;
                       [self asynchronouslyVisitObject:nextObjectIt
                                                ofList:list
                                               onQueue:queue
                                            usingBlock:block
                                     completionHandler:completionHandler];
                   }
               });
    }];
}

#pragma mark - Memory Pressure

- (void)createMemoryPressureObserver
{
    NSAssert(!_memoryPressureObserver, nil);

    _memoryPressureObserver = [[PWDispatchMemoryPressureObserver alloc] initWithFlags:DISPATCH_MEMORYPRESSURE_WARN | DISPATCH_MEMORYPRESSURE_CRITICAL
                                                                        dispatchQueue:_dispatchQueue];
    __weak typeof(self) weakSelf = self;
    _memoryPressureObserver.eventBlock = ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf evictAsManyObjectsAsPossibleWithCompletionHandler:^{
        }];
    };
    [_memoryPressureObserver enable];
    
}

#pragma mark - For unit testing

- (NSUInteger)count
{
    __block NSUInteger count;
    [_dispatchQueue synchronouslyDispatchBlock:^{
        count = _map.size();
    }];
    return count;
}

- (nullable id)objectForKey:(id)key
{
    __block id result;
    PWDispatchSemaphore* semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    [self objectForKey:key completionHandler:^(id _Nullable object) {
        result = object;
        [semaphore signal];
    }];
    [semaphore waitForever];
    return result;
}

- (void)setObject:(nullable id)obj forKeyedSubscript:(id)key
{
    [self setObject:obj forKey:key];
}

- (nullable id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}
@end

NS_ASSUME_NONNULL_END
