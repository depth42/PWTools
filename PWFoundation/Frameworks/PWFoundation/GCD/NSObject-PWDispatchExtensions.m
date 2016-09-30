//
//  NSObject-PWDispatchExtensions.m
//  PWFoundation
//
//  Created by Andreas Känner on 8/11/09.
//
//

#import "NSObject-PWDispatchExtensions.h"
#import "PWDispatchKeyValueObserver.h"
#import "PWDispatch.h"
#import "PWEnumerable.h"
#import "NSObject-PWExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSObject (PWDispatchExtensions)

- (PWDispatchObserver*)addObserverForKeyPaths:(id <PWEnumerable>)keyPaths
                                      options:(NSKeyValueObservingOptions)options
                                dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                                 dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
                                   usingBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block
{
    NSParameterAssert(keyPaths.elementCount > 0);
    return [[PWDispatchKeyValueObserver alloc] initWithDispatchQueue:queue ? queue : PWDispatchQueue.mainQueue
                                                       observerBlock:block
                                                        dispatchKind:dispatchKind
                                                     observedObjects:@[self]
                                                            keyPaths:keyPaths
                                                             options:options];
}

+ (nullable PWDispatchObserver*)observeKeyPaths:(id <PWEnumerable>)keyPaths
                                      ofObjects:(id <PWEnumerable>)objects
                                        options:(NSKeyValueObservingOptions)options
                                  dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                                   dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
                                     usingBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block
{
    if(keyPaths.elementCount == 0 || objects.elementCount == 0)
        return nil;
    return [[PWDispatchKeyValueObserver alloc] initWithDispatchQueue:queue ? queue : PWDispatchQueue.mainQueue
                                                       observerBlock:block
                                                        dispatchKind:dispatchKind
                                                     observedObjects:objects
                                                            keyPaths:keyPaths
                                                             options:options];
}

// OBSOLETE variants, forward to above with dispatchKind.
- (nullable PWDispatchObserver*)addObserverForKeyPaths:(id <PWEnumerable>)keyPaths
                                               options:(NSKeyValueObservingOptions)options
                                         dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                                         synchronously:(BOOL)synchronous
                                            usingBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block
{
    return [self addObserverForKeyPaths:keyPaths
                                options:options
                          dispatchQueue:queue
                           dispatchKind:synchronous ? PWDispatchQueueDispatchKindSynchronous : PWDispatchQueueDispatchKindAsynchronous
                             usingBlock:block];
}

- (nullable PWDispatchObserver*)addObserverForKeyPath:(NSString*)keyPath
                                              options:(NSKeyValueObservingOptions)options
                                        dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                                        synchronously:(BOOL)synchronous
                                           usingBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block
{
    return [self addObserverForKeyPaths:keyPath
                                options:options
                          dispatchQueue:queue
                           dispatchKind:synchronous ? PWDispatchQueueDispatchKindSynchronous : PWDispatchQueueDispatchKindAsynchronous
                             usingBlock:block];
}

+ (nullable PWDispatchObserver*)observeKeyPaths:(id <PWEnumerable>)keyPaths
                                      ofObjects:(id <PWEnumerable>)objects
                                        options:(NSKeyValueObservingOptions)options
                                  dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                                  synchronously:(BOOL)synchronous
                                     usingBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block
{
    return [self observeKeyPaths:keyPaths
                       ofObjects:objects
                         options:options
                   dispatchQueue:queue
                    dispatchKind:synchronous ? PWDispatchQueueDispatchKindSynchronous : PWDispatchQueueDispatchKindAsynchronous
                      usingBlock:block];
}

- (void)afterDelay:(NSTimeInterval)delay performBlock:(PWDispatchBlock)block
{
    NSParameterAssert(block);
    NSParameterAssert(delay >= 0.0);
    [NSObject performSelector:@selector(pw_performDelayedBlock:) withObject:[block copy] afterDelay:delay];
}

- (void)afterDelay:(NSTimeInterval)delay inModes:(NSArray*)modes performBlock:(PWDispatchBlock)block 
{
    [NSObject performSelector:@selector(pw_performDelayedBlock:) withObject:[block copy] afterDelay:delay inModes:modes];
}

+ (void)pw_performDelayedBlock:(PWDispatchBlock)block
{
    NSParameterAssert(block);
    block();
}
@end

NS_ASSUME_NONNULL_END
