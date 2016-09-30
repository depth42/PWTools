#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5

//
//  PWDispatchSource.m
//  PWFoundation
//
//  Created by Kai Brüning on 16.6.09.
//
//

#import "PWDispatchSource.h"
#import "PWDispatchQueueing.h"
#import "PWDispatchQueue-Private.h"
#import "PWDispatchObject-Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchSource

- (instancetype) initWithType:(dispatch_source_type_t)type
             handle:(uintptr_t)handle
               mask:(NSUInteger)mask
            onQueue:(id<PWDispatchQueueing>)queue
{
    NSParameterAssert (type);
    NSParameterAssert (queue);

    dispatch_source_t newSource = dispatch_source_create (type,
                                                          handle,
                                                          mask,
                                                          queue.dispatchQueueForNativeAPIs.underlyingQueue);
    if (!newSource)
        return nil;
    if ((self = [super initWithUnderlyingObject:newSource]) != nil)
    {
        _queue = queue;
        isDisabled_ = 1; // Sources are created suspended
    }
    return self;
}

- (void) setEventBlock:(nullable PWDispatchBlock)handler
{
    if (handler)
        dispatch_source_set_event_handler ((dispatch_source_t)impl_,
                                           PWDispatchCreateNativeAPIWrapperBlock (_queue, handler));
    else
        dispatch_source_set_event_handler ((dispatch_source_t)impl_, NULL);
}

- (void) setCancelBlock:(nullable PWDispatchBlock)handler
{
    if (handler)
        dispatch_source_set_cancel_handler ((dispatch_source_t)impl_,
                                            PWDispatchCreateNativeAPIWrapperBlock (_queue, handler));
    else
        dispatch_source_set_cancel_handler ((dispatch_source_t)impl_, NULL);
}

- (void) cancel
{
    dispatch_source_cancel ((dispatch_source_t)impl_);
}

- (BOOL) isCancelled
{
    return dispatch_source_testcancel ((dispatch_source_t)impl_) != 0;
}

- (dispatch_source_t) underlyingSource
{
    return (dispatch_source_t)impl_;
}

- (unsigned long)data
{
    return dispatch_source_get_data((dispatch_source_t)impl_);
}

- (void) dealloc
{
    if(impl_)
    {
        [self enable];
        [self cancel];
    }
}

@end

#endif /* Availability */

NS_ASSUME_NONNULL_END
