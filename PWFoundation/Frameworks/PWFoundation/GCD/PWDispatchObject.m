#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5

//
//  PWDispatchObject.m
//  PWFoundation
//
//  Created by Kai Brüning on 15.6.09.
//
//

#import "PWDispatchObject.h"
#import "PWDispatchObject-Internal.h"
#import "PWDispatchQueue.h"
#import "PWDispatchQueueGraph.h"
#include <libkern/OSAtomic.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchObject

@synthesize underlyingObject = impl_;
@synthesize targetQueue      = targetQueue_;

- (instancetype) initWithUnderlyingObject:(dispatch_object_t)anImpl
{
    NSParameterAssert (anImpl);
    if ((self = [super init]) != nil)
    {
        impl_ = anImpl;
    }
    return self;
}

#if PWDISPATCH_USE_QUEUEGRAPH
- (void) dealloc
{
    [PWDispatchQueueGraph.sharedGraph removeDispatchObject:self];
}
#endif

- (void) setFinalizerFunction:(nullable dispatch_function_t)finalizer
{
    NSAssert(impl_, nil);
    dispatch_set_finalizer_f (impl_, finalizer);
}

- (void) setTargetQueue:(nullable PWDispatchQueue*)aQueue
{
    NSAssert(impl_, nil);
    targetQueue_ = aQueue;
    dispatch_set_target_queue (impl_, aQueue.underlyingQueue);
}

- (void) suspend
{
    NSAssert(impl_, nil);
    dispatch_suspend (impl_);
}

- (void) resume
{
    NSAssert(impl_, nil);
    NSAssert (!isDisabled_, @"must use -enable to balance -disable");
    dispatch_resume (impl_);
}

- (void) disable
{
    if(!OSAtomicTestAndSetBarrier(7, &isDisabled_))
    {
        [self suspend];
    }
}

- (void) enable
{
    if(OSAtomicTestAndClearBarrier(7, &isDisabled_))
    {
        [self resume];
    }
}

- (nullable void*) context
{
    NSAssert(impl_, nil);
    return dispatch_get_context (impl_);
}

- (void) setContext:(nullable void*)value
{
    NSAssert(impl_, nil);
    dispatch_set_context (impl_, value);
}

- (BOOL)isDisabled
{
    return (BOOL)isDisabled_;
}

@end

dispatch_time_t PWDispatchTimeFromDate (NSDate* date)
{
    NSCParameterAssert (date);
    
    NSTimeInterval interval = date.timeIntervalSince1970;
    
    double seconds;
    double subSeconds = modf (interval, &seconds);
    
    struct timespec time;
    time.tv_sec = seconds;
    time.tv_nsec = subSeconds * NSEC_PER_SEC;

    return dispatch_walltime (&time, 0);
}


#endif /* Availability */

NS_ASSUME_NONNULL_END
