#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5

//
//  PWDispatchTimer.m
//  PWFoundation
//
//  Created by Kai Brüning on 16.6.09.
//
//

#import "PWDispatchTimer.h"
#import "PWDispatchTimer-Private.h"
#import "PWDispatchSource-Internal.h"
#import "PWDispatchQueue-Private.h"
#import "PWDispatchObject-Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchTimer

+ (PWDispatchTimer*) enabledTimerWithQueue:(id<PWDispatchQueueing>)queue
                      startIntervalFromNow:(NSTimeInterval)startInterval
                        repetitionInterval:(NSTimeInterval)repetitionInterval 
                                    leeway:(NSTimeInterval)leeway
                               useWallTime:(BOOL)useWallTime
                                eventBlock:(PWDispatchBlock)handler
{
    NSParameterAssert (queue);
    return [[queue.dispatchQueueForNativeAPIs.dispatchTimerClass alloc] initAndEnableWithQueue:queue
                                                                            startIntervalFromNow:startInterval
                                                                              repetitionInterval:repetitionInterval
                                                                                          leeway:leeway
                                                                                     useWallTime:useWallTime
                                                                                      eventBlock:handler];
}

+ (PWDispatchTimer*) enabledSingleShotTimerWithQueue:(id<PWDispatchQueueing>)queue
                                 fireIntervalFromNow:(NSTimeInterval)fireInterval
                                              leeway:(NSTimeInterval)leeway
                                         useWallTime:(BOOL)useWallTime
                                          eventBlock:(PWDispatchBlock)handler
{
    NSParameterAssert (queue);
    return [[queue.dispatchQueueForNativeAPIs.dispatchTimerClass alloc] initAndEnableWithQueue:queue
                                                                           fireIntervalFromNow:fireInterval
                                                                                        leeway:leeway
                                                                                   useWallTime:useWallTime
                                                                                    eventBlock:handler];
}

- (instancetype) initAndEnableWithQueue:(id<PWDispatchQueueing>)queue
         startIntervalFromNow:(NSTimeInterval)startInterval
           repetitionInterval:(NSTimeInterval)repetitionInterval
                       leeway:(NSTimeInterval)leeway
                  useWallTime:(BOOL)useWallTime
                   eventBlock:(PWDispatchBlock)handler
{
    NSParameterAssert (handler);
    
    if ((self = [self initPrivateWithQueue:queue]) != nil) {
        [self setEventBlock:handler];
        [self setStartIntervalFromNow:startInterval 
                   repetitionInterval:repetitionInterval
                               leeway:leeway
                          useWallTime:useWallTime];
        [self enable];
    }
    return self;
}

- (instancetype) initAndEnableWithQueue:(id<PWDispatchQueueing>)queue
          fireIntervalFromNow:(NSTimeInterval)fireInterval
                       leeway:(NSTimeInterval)leeway
                  useWallTime:(BOOL)useWallTime
                   eventBlock:(PWDispatchBlock)handler
{
    NSParameterAssert (handler);
    
    if ((self = [self initPrivateWithQueue:queue]) != nil) {
        [self setEventBlock:handler];
        [self setFireIntervalFromNow:fireInterval 
                              leeway:leeway
                         useWallTime:useWallTime];
        [self enable];
    }
    return self;
}

- (instancetype) initPrivateWithQueue:(id<PWDispatchQueueing>)queue
{
    return [super initWithType:DISPATCH_SOURCE_TYPE_TIMER handle:0 mask:0 onQueue:queue];
}

- (instancetype) initWithQueue:(id<PWDispatchQueueing>)queue
{
    // TODO: replace object only if necessary.
    return [[queue.dispatchQueueForNativeAPIs.dispatchTimerClass alloc] initPrivateWithQueue:queue];
}

- (void) setStartIntervalFromNow:(NSTimeInterval)startInterval
              repetitionInterval:(NSTimeInterval)repetitionInterval 
                          leeway:(NSTimeInterval)leeway
                     useWallTime:(BOOL)useWallTime
{
    int64_t startDelta = (int64_t)(startInterval * (double)NSEC_PER_SEC);
    dispatch_source_set_timer((dispatch_source_t)impl_,
                              useWallTime ? dispatch_walltime(NULL, startDelta) : dispatch_time(0, startDelta),
                              (int64_t)(repetitionInterval * (double)NSEC_PER_SEC),
                              (int64_t)(leeway * (double)NSEC_PER_SEC));
}

- (void) setFireIntervalFromNow:(NSTimeInterval)fireInterval
                         leeway:(NSTimeInterval)leeway
                    useWallTime:(BOOL)useWallTime
{
    // Dispatch timers are always repeating, this is concealed here by passing a very long repetition interval.
    // The parameter type is uint64_t, therefore there’s no danger of overflow when using the signed max LLONG_MAX.
    int64_t startDelta = (int64_t)(fireInterval * (double)NSEC_PER_SEC);
    dispatch_source_set_timer((dispatch_source_t)impl_,
                              useWallTime ? dispatch_walltime(NULL, startDelta) : dispatch_time(0, startDelta),
                              LLONG_MAX,
                              (int64_t)(leeway * (double)NSEC_PER_SEC));
}

- (NSUInteger) fireCount
{
    return dispatch_source_get_data ((dispatch_source_t)impl_);
}

@end

#endif /* Availability */

NS_ASSUME_NONNULL_END
