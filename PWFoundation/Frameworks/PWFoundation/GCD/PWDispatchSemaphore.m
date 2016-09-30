#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5

//
//  PWDispatchSemaphore.m
//  PWFoundation
//
//  Created by Kai Brüning on 30.6.09.
//
//

#import "PWDispatchSemaphore.h"
#import "PWDispatchObject-Internal.h"
#import "PWDispatchQueueGraph.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchSemaphore
{
#if PWDISPATCH_USE_QUEUEGRAPH
    _Atomic(BOOL)   _isExcludedFromQueueGraph;
#endif
}

- (instancetype) initWithInitialValue:(long)value
{
    dispatch_semaphore_t newSemaphore = dispatch_semaphore_create (value);
    if (!newSemaphore)
        return nil;
    
    return [super initWithUnderlyingObject:newSemaphore];
}

- (BOOL) waitWithTimeout:(NSTimeInterval)timeout useWallTime:(BOOL)useWallTime
{
#if PWDISPATCH_USE_QUEUEGRAPH
    if (!_isExcludedFromQueueGraph)
        [PWDispatchQueueGraph.sharedGraph addSynchronousDispatchToQueue:self];
#endif
    
    int64_t nanoseconds = (int64_t)(timeout * (double)NSEC_PER_SEC);
    dispatch_time_t time = useWallTime ? dispatch_walltime(NULL, nanoseconds) : dispatch_time(0, nanoseconds);
    return dispatch_semaphore_wait ((dispatch_semaphore_t)impl_, time) == 0;
}

- (void) waitForever
{
#if PWDISPATCH_USE_QUEUEGRAPH
    if (!_isExcludedFromQueueGraph)
        [PWDispatchQueueGraph.sharedGraph addSynchronousDispatchToQueue:self];
#endif

    dispatch_semaphore_wait ((dispatch_semaphore_t)impl_, DISPATCH_TIME_FOREVER);
}

- (BOOL) signal
{
#if PWDISPATCH_USE_QUEUEGRAPH
    id<PWDispatchQueueGraphLabeling> currentQueue = PWDispatchQueueGraph.innermostCurrentDispatchQueue;
    if (currentQueue)
        [PWDispatchQueueGraph.sharedGraph addSynchronousDispatchFromQueue:self toQueue:currentQueue];
#endif

    return dispatch_semaphore_signal ((dispatch_semaphore_t)impl_) != 0;
}

@end

#endif /* Availability */

NS_ASSUME_NONNULL_END
