//
//  PWLRUCache.m
//  PWFoundation
//
//  Created by Frank Illenberger on 08.10.15.
//  Copyright © 2015 ProjectWizards. All rights reserved.
//

#import "PWLRUCache.h"
#import <unordered_map>
#import <list>
#import "PWDispatch.h"

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
typedef std::list<KeyObjectPair>::iterator ListIterator;

@implementation PWLRUCache
{
    std::list<KeyObjectPair> _leastRecentUsageList;
    std::unordered_map<__unsafe_unretained id, ListIterator, Hash, EqualTo> _map;
    PWDispatchMemoryPressureObserver* _memoryPressureObserver;
}

- (instancetype)initWithCapacity:(NSUInteger)capacity
                        delegate:(nullable id<PWLRUCacheDelegate>)delegate
                   dispatchQueue:(id <PWDispatchQueueing>)dispatchQueue
{
    NSParameterAssert(capacity != NSNotFound && capacity > 0);

    self = [super init];

    _capacity = capacity;
    _delegate = delegate;
    _dispatchQueue = dispatchQueue;
    [self createMemoryPressureObserver];

    return self;
}

- (void)dealloc
{
    [_dispatchQueue synchronouslyDispatchBlock:^{
        [_memoryPressureObserver cancel];
        id <PWLRUCacheDelegate> delegate = _delegate;
        if(delegate)
            for(auto iPair : _leastRecentUsageList)
                [delegate cache:self willRemoveObject:iPair.second];
    }];
}

- (NSUInteger)count
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);

    return _map.size();
}

- (void)setObject:(nullable id)object forKey:(id)key
{
    NSParameterAssert(key);
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);

    [self removeObjectForKey:key];

    if(object)
    {
        [self _setObject:object forKey:key];

        if (self.count > _capacity)
            [self removeLeastRecentlyUsedObject];
    }
}

- (void)_setObject:(id)object forKey:(id)key
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);

    _leastRecentUsageList.push_front(KeyObjectPair(key, object));
    _map[key] = _leastRecentUsageList.begin();
}

- (BOOL)removeLeastRecentlyUsedObject
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);

    if(_leastRecentUsageList.empty())
        return NO;

    auto last = _leastRecentUsageList.end();
    last--;

    // We first ask the delegate for permission, if it refuses, we do not evict.
    id<PWLRUCacheDelegate> delegate = _delegate;    // weak -> strong
    if(delegate)
    {
        if(![delegate cache:self canEvictObject:last->second])
            return NO;
        [delegate cache:self willRemoveObject:last->second];
    }

    _map.erase(last->first);
    _leastRecentUsageList.pop_back();
    return YES;
}

- (nullable id)objectForKey:(id)key
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);

    auto match = _map.find(key);
    if (match == _map.end())
        return nil;
    else
    {
        // Everytime an object is returned, move it to the front of the least recent usage list.
        _leastRecentUsageList.splice(_leastRecentUsageList.begin(), _leastRecentUsageList, match->second);
        return match->second->second;
    }
}

- (void)removeObjectForKey:(id)key
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);

    auto it = _map.find(key);
    if (it != _map.end())
    {
        [_delegate cache:self willRemoveObject:it->second->second];
        _leastRecentUsageList.erase(it->second);
        _map.erase(it);
    }
}

- (void)removeAllObjects
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);

    id <PWLRUCacheDelegate> delegate = _delegate;
    if(delegate)
        for(auto it : _leastRecentUsageList)
            [delegate cache:self willRemoveObject:it.second];

    _map.clear();
    _leastRecentUsageList.clear();
}

- (void)evictAsManyObjectsAsPossible
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);

    id <PWLRUCacheDelegate> delegate = _delegate;
    if(!delegate)
    {
        [self removeAllObjects];
        return;
    }

    auto it = _leastRecentUsageList.begin();
    while(it != _leastRecentUsageList.end())
    {
        if([delegate cache:self canEvictObject:it->second])
        {
            [delegate cache:self willRemoveObject:it->second];
            _map.erase(it->first);
            it = _leastRecentUsageList.erase(it);
        }
        else
            ++it;
    }
}

#pragma mark - Keyed Subscripting

- (nullable id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(nullable id)obj forKeyedSubscript:(id)key
{
    [self setObject:obj forKey:key];
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
        [strongSelf evictAsManyObjectsAsPossible];
    };
    [_memoryPressureObserver enable];

}
@end

NS_ASSUME_NONNULL_END
