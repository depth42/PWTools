//
//  PWDispatchFoundationTimer.m
//  PWFoundation
//
//  Created by Kai Brüning on 16.8.11.
//
//

#import "PWDispatchFoundationTimer.h"
#import "PWDispatchTimer-Private.h"
#import "PWDispatchQueue.h"
#import "PWDispatchObject-Internal.h"

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchFoundationTimer ()

- (void) setStartIntervalAndStartTimer:(NSTimeInterval)startInterval;
- (void) startTimerIfNecessary;

@end

#pragma mark -

@implementation PWDispatchFoundationTimer
{
    NSTimer*        timer_;

    // The handler is set to nil if cancelled. In this case most methods do nothing (same as dispatch’s behavior).
    PWDispatchBlock handler_;
    
    PWDispatchBlock cancelHandler_;
    NSTimeInterval  repetitionInterval_;    // 0.0 for single shot
    NSDate*         fireDate_;
    int             suspendCount_;
}

- (id) initAndEnableWithQueue:(id<PWDispatchQueueing>)queue
         startIntervalFromNow:(NSTimeInterval)startInterval
           repetitionInterval:(NSTimeInterval)repetitionInterval 
                       leeway:(NSTimeInterval)leeway
                  useWallTime:(BOOL)useWallTime
                   eventBlock:(PWDispatchBlock)handler
{
    NSParameterAssert (handler);
    
    if ((self = [self initPrivateWithQueue:queue]) != nil) {
        repetitionInterval_ = repetitionInterval;
        handler_ = [handler copy];
        fireDate_ = [NSDate dateWithTimeIntervalSinceNow:startInterval];
        [self enable];
    }
    return self;
}

- (id) initAndEnableWithQueue:(id<PWDispatchQueueing>)queue
          fireIntervalFromNow:(NSTimeInterval)fireInterval
                       leeway:(NSTimeInterval)leeway
                  useWallTime:(BOOL)useWallTime
                   eventBlock:(PWDispatchBlock)handler
{
    NSParameterAssert (handler);
    
    if ((self = [self initPrivateWithQueue:queue]) != nil) {
        handler_ = [handler copy];
        fireDate_ = [NSDate dateWithTimeIntervalSinceNow:fireInterval];
        [self enable];
    }
    return self;
}

- (id) initPrivateWithQueue:(id<PWDispatchQueueing>)queue
{
    NSParameterAssert (queue == PWDispatchQueue.mainQueue);
    
    // Circumvent any real initialization of a dispatch source/timer
    if ((self = [super init]) != nil) {
        // Set a dummy handler to fullfil the invariant (handler_ != nil) == (is not cancelled)
        handler_ = [^(){} copy];
        // Sources are created suspended
        isDisabled_ = 1;
        suspendCount_ = 1;
    }
    return self;
}


- (id) initWithQueue:(id<PWDispatchQueueing>)queue
{
    return [self initPrivateWithQueue:queue];
}

- (void) executeBlockOnMainThread:(PWDispatchBlock)block
{
    NSParameterAssert (block);
    if ([NSThread isMainThread])
        block();
    else
        [PWDispatchQueue.mainQueue asynchronouslyDispatchBlock:block];
}

- (void) setStartIntervalFromNow:(NSTimeInterval)startInterval
              repetitionInterval:(NSTimeInterval)repetitionInterval 
                          leeway:(NSTimeInterval)leeway
                     useWallTime:(BOOL)useWallTime
{
    NSParameterAssert (repetitionInterval > 0.0);
    
    [self executeBlockOnMainThread:^() {
        if (handler_) { // ignore if timer is cancelled
            if (timer_ && repetitionInterval != timer_.timeInterval) {
                [timer_ invalidate];
                timer_ = nil;
            }
            repetitionInterval_ = repetitionInterval;
            [self setStartIntervalAndStartTimer:startInterval];
        }
    }];
}

- (void) setFireIntervalFromNow:(NSTimeInterval)fireInterval
                         leeway:(NSTimeInterval)leeway
                    useWallTime:(BOOL)useWallTime
{
    [self executeBlockOnMainThread:^() {
        if (handler_) { // ignore if timer is cancelled
            if (timer_ && timer_.timeInterval != 0.0) {
                [timer_ invalidate];
                timer_ = nil;
            }
            repetitionInterval_ = 0.0;
            [self setStartIntervalAndStartTimer:fireInterval];
        }
    }];
}

- (void) setStartIntervalAndStartTimer:(NSTimeInterval)startInterval
{
    NSAssert ([NSThread isMainThread], nil);
    NSAssert (handler_, nil);
    
    NSDate* fireDate = [NSDate dateWithTimeIntervalSinceNow:startInterval];
    if (timer_)
        timer_.fireDate = fireDate;
    else {
        fireDate_ = fireDate;
        if (suspendCount_ == 0)
            [self startTimerIfNecessary];
    }
}

- (void) suspend
{
    [self executeBlockOnMainThread:^() {
        if (++suspendCount_ == 1) {
            // Only way to suspend an NSTimer is to kill it (besides just ignoring its firing, of course).
            if (timer_) {
                fireDate_ = timer_.fireDate;
                repetitionInterval_ = timer_.timeInterval;   // 0 for non-repeating timer
                [timer_ invalidate];
                timer_ = nil;
            }
        }
    }];
}

- (void) resume
{
    [self executeBlockOnMainThread:^() {
        NSCAssert (!isDisabled_, @"must use -enable to balance -disable");

        NSCAssert (suspendCount_ > 0, nil);
        if (--suspendCount_ == 0) {
            NSCAssert (!timer_, nil);
            if (handler_) // ignore if timer is cancelled
                [self startTimerIfNecessary];
        }
    }];
}

- (void) startTimerIfNecessary
{
    NSAssert ([NSThread isMainThread], nil);
    NSAssert (!timer_, nil);
    NSAssert (handler_, nil);   // must not be cancelled
    
    if (fireDate_) {
        timer_ = [[NSTimer alloc] initWithFireDate:fireDate_
                                          interval:repetitionInterval_
                                            target:self
                                          selector:@selector(fire:)
                                          userInfo:nil
                                           repeats:repetitionInterval_ > 0.0];
        
        [[NSRunLoop mainRunLoop] addTimer:timer_ forMode:NSRunLoopCommonModes];
    }
}

- (NSUInteger) fireCount
{
    return 1;   // NSTimer does not support the count concept
}

- (void) setEventBlock:(nullable PWDispatchBlock)handler
{
    NSParameterAssert (handler);
    
    // Must make the copy immediately, because executeBlockOnMainThread can be asynchronous.
    handler = [handler copy];
    
    [self executeBlockOnMainThread:^() {
        if (handler_) // ignore if timer is cancelled
            handler_ = handler;
    }];
}

- (void) setCancelBlock:(nullable PWDispatchBlock)handler
{
    // Must make the copy immediately, because executeBlockOnMainThread can be asynchronous.
    handler = [handler copy];
    [self executeBlockOnMainThread:^() { cancelHandler_ = handler; }];
}

- (void) cancel
{
    [self executeBlockOnMainThread:^() {
        if (handler_) {     // ignore if timer already cancelled
            handler_ = nil;
            [timer_ invalidate];
            timer_ = nil;
            if (cancelHandler_)
                cancelHandler_();
        }
    }];
}

- (BOOL) isCancelled
{
    // dispatch_source_testcancel() returns YES immediately after dispatch_source_cancel has been called.
    // Implementing this would necessitate a thread safe "is cancelled" state - let’s do this if really needed.
    [NSException raise:NSInternalInconsistencyException format:@"isCancelled is not yet implemented in PWDispatchFoundationTimer"];
    return NO;
}

- (dispatch_source_t) underlyingSource
{
    [NSException raise:NSInternalInconsistencyException format:@"PWDispatchFoundationTimer has no dispatch source"];
    return NULL;
}

- (unsigned long)data
{
    [NSException raise:NSInternalInconsistencyException format:@"PWDispatchFoundationTimer has no dispatch data"];
    return 0;
}


- (void) fire:(NSTimer*)timer
{
    NSAssert ([NSThread isMainThread], nil);
    NSAssert (handler_, nil);
    
    // Keep the handler block alive in case the timer is cancelled from within the block.
    PWDispatchBlock handler = handler_;

    if (timer.timeInterval == 0.0) {    // ->  non-repeating timer
        fireDate_ = nil;
        repetitionInterval_ = 0.0;
        timer_ = nil;
    }
    
    handler();
}

@end

NS_ASSUME_NONNULL_END
