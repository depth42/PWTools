//
//  PWDispatchMainQueue.m
//  PWFoundation
//
//  Created by Kai Brüning on 16.8.11.
//
//

#import "PWDispatchMainQueue.h"
#import "PWDispatchQueue-Private.h"
#import "PWDispatchObject-Internal.h"
#import "PWDispatchFoundationTimer.h"
#import "PWDispatchMainQueueTimer.h"
#import "PWDispatchQueueGraph.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchMainQueue

// Overwritten from PWDispatchQueue.
- (id) initWithLabel:(NSString*)aLabel
{
    NSAssert (NO, @"illegal initialization of main queue");
    return nil;
}

// Overwritten from PWDispatchQueue.
- (instancetype) initWithUnderlyingObject:(dispatch_object_t)anImpl
{
    if(self = [super initWithUnderlyingObject:anImpl])
    {
        // Always create a timer queue. There is only one dispatch main queue, so the additional queue instance variable
        // does no harm. Also, we avoid any race conditions during creation on demand.
        
        _timerQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"MainQueueTimer"];
    }

    return self;
}

- (void) asynchronouslyDispatchBlock:(PWDispatchBlock)block
{
    if (_mapToFoundation)
        [self performSelectorOnMainThread:@selector(callBlock:) withObject:[block copy] waitUntilDone:NO
                                    modes:@[NSRunLoopCommonModes]];
    else
        [super asynchronouslyDispatchBlock:block];
}

// Commented out asynchrounous dispatch methods, so the original implementation in PWDispatchQueue is in effect. As
// these methods add a delay or even dispatch at a specific date (probably seconds or minutes into the future), there
// will probably be some time to dispatch them and a little delay would not do much harm.

// In case we still need to overwrite them, a dispatch timer on the timer queue would be the way to do it (calling into
// the main queue using performSelectorOnMainThread:withObject:waitUntilDone:modes:).

//- (void) asynchronouslyDispatchAfterDelay:(NSTimeInterval)delay 
//                              useWallTime:(BOOL)useWallTime
//                                    block:(PWDispatchBlock)block
//{
//    NSParameterAssert (delay > 0.0);
//    NSParameterAssert (block);
//
//    if (_mapToFoundation) {
//        NSTimer* timer = [NSTimer timerWithTimeInterval:delay
//                                                 target:self
//                                               selector:@selector(callBlockFromTimer:)
//                                               userInfo:[block copy]
//                                                repeats:NO];
//        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
//    } else
//        [super asynchronouslyDispatchAfterDelay:delay useWallTime:useWallTime block:block];
//}
//
//- (void) asynchronouslyDispatchAfterDate:(NSDate*)date block:(PWDispatchBlock)block
//{
//    NSParameterAssert (date);
//    NSParameterAssert (block);
//
//    if (_mapToFoundation) {
//        NSTimer* timer = [[NSTimer alloc] initWithFireDate:date
//                                                  interval:0.0  // unused for one-shot timer
//                                                    target:self
//                                                  selector:@selector(callBlockFromTimer:)
//                                                  userInfo:[block copy]
//                                                   repeats:NO];
//        [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
//    } else
//        [super asynchronouslyDispatchAfterDate:date block:block];
//}
//
//- (void) callBlockFromTimer:(NSTimer*)timer
//{
//    ((PWDispatchBlock) timer.userInfo)();
//}

- (void) synchronouslyDispatchBlock:(PWDispatchBlock)inBlock
{
    NSParameterAssert(inBlock);

    if(pthread_main_np() != 0)
    {
        inBlock();
        return;
    }

    // The main queue is the only queue in GCD for which the thread is switched when performing a synchronous dispatch
    // from another queue. To be able to perform the -isCurrentDispatchQueue check in non-main queues, we keep book
    // about the thread from which the main queue is synchronously entered.
    pthread_t thread = pthread_self();
    // The source queue must be read before the thread switch, too.
#if PWDISPATCH_USE_QUEUEGRAPH
    id<PWDispatchQueueGraphLabeling> sourceQueue = PWDispatchQueueGraph.innermostCurrentDispatchQueue;
#endif

    PWDispatchBlock block = ^{
    #if PWDISPATCH_USE_QUEUEGRAPH
        [PWDispatchQueueGraph.sharedGraph addSynchronousDispatchFromQueue:sourceQueue toQueue:self];

        // Note: no +pushCurrentDispatchQueueElement:... here because the main queue always runs on the main thread,
        // which is primed with the main queue as being current.
    #endif
        
        _synchronouslyEnteredFromThread = thread;
        inBlock();
        _synchronouslyEnteredFromThread = NULL;
    };

    if (_mapToFoundation)
        // Note: performSelectorOnMainThread: with waitUntilDone:YES does not block if send from the main thread.
        [self performSelectorOnMainThread:@selector(callBlock:) withObject:[block copy] waitUntilDone:YES
                                    modes:@[NSRunLoopCommonModes]];
    else
        dispatch_sync ((dispatch_queue_t)impl_, block);
}

- (void) callBlock:(PWDispatchBlock)block
{
    NSParameterAssert(block);

    block();
    // Make current queue check work for a block dispatched directly to GCD.
//    [self asCurrentQueuePerformBlock:block];
}

- (Class) dispatchTimerClass
{
    // Note: Use a specialized timer for the main queue. This is to prevent starving of timer events by using a dispatch
    // timer on another queue and calling back into the main thread.
    
    return _mapToFoundation ? PWDispatchMainQueueTimer.class : super.dispatchTimerClass;
}

- (BOOL) isCurrentDispatchQueue
{
    return pthread_main_np() != 0;
}

@end

NS_ASSUME_NONNULL_END
