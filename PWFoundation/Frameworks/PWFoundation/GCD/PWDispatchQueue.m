//
//  PWDispatchQueue.m
//  PWFoundation
//
//  Created by Kai Brüning on 15.6.09.
//
//

#import "PWDispatchQueue.h"
#import "PWDispatchQueue-Private.h"
#import "PWDispatchGroup.h"
#import "PWDispatchObject-Internal.h"
#import "PWDispatchMainQueue.h"
#import "PWDispatchTimer.h"
#import "PWDispatchQueueGraph.h"
#import <PWFoundation/PWAsserts.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct DispatchContext
{
    __unsafe_unretained PWDispatchBlock   block;
    __unsafe_unretained PWDispatchQueue*  queue;
} DispatchContext;

@implementation PWDispatchQueue

static PWDispatchMainQueue* mainQueue;
static PWDispatchQueue* lowPriorityQueue;
static PWDispatchQueue* defaultPriorityQueue;
static PWDispatchQueue* highPriorityQueue;

+ (void) initialize
{
    if (self == PWDispatchQueue.class)
    {
        mainQueue               = [[PWDispatchMainQueue alloc] initWithUnderlyingObject:dispatch_get_main_queue()];
        mainQueue.mapToFoundation = YES;
        
        lowPriorityQueue        = [[PWDispatchQueue alloc] initWithUnderlyingObject:dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_LOW, 0)];
        defaultPriorityQueue    = [[PWDispatchQueue alloc] initWithUnderlyingObject:dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
        highPriorityQueue       = [[PWDispatchQueue alloc] initWithUnderlyingObject:dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    }
}

+ (PWDispatchQueue*) mainQueue
{
    return mainQueue;
}

+ (PWDispatchQueue*) globalDefaultPriorityQueue
{
    return defaultPriorityQueue;
}

+ (PWDispatchQueue*) globalLowPriorityQueue
{
    return lowPriorityQueue;
}

+ (PWDispatchQueue*) globalHighPriorityQueue
{
    return highPriorityQueue;
}

+ (PWDispatchQueue*) serialDispatchQueueWithLabel:(nullable NSString*)label
{
    dispatch_queue_t newQueue = dispatch_queue_create (label.UTF8String, DISPATCH_QUEUE_SERIAL);
    PWReleaseAssert (newQueue, @"could not create a serial dispatch queue");
    return [[PWSerialDispatchQueue alloc] initWithUnderlyingObject:newQueue];
}

+ (PWConcurrentDispatchQueue*) concurrentDispatchQueueWithLabel:(nullable NSString*)label
{
    dispatch_queue_t newQueue = dispatch_queue_create (label.UTF8String, DISPATCH_QUEUE_CONCURRENT);
    PWReleaseAssert (newQueue, @"could not create a concurrent dispatch queue");
    return [[PWConcurrentDispatchQueue alloc] initWithUnderlyingObject:newQueue];
}

- (instancetype) init
{
    NSAssert(NO, nil);
    return nil;
}

- (instancetype) initWithUnderlyingObject:(dispatch_object_t)anImpl
{
    return [super initWithUnderlyingObject:anImpl];
}

- (PWDispatchQueue*) dispatchQueueForNativeAPIs
{
    return self;
}

NS_INLINE DispatchContext* createAsyncDispatchContext (__unsafe_unretained PWDispatchQueue* queue,
                                                       __unsafe_unretained PWDispatchBlock block)
{
    DispatchContext* context = malloc(sizeof(DispatchContext));
    context->queue = CFRetain((__bridge CFTypeRef)(queue));
    context->block = (__bridge PWDispatchBlock)(Block_copy((__bridge const void *)(block)));
    return context;
}

void doAsyncDispatch (void* inContext)
{
    NSCParameterAssert(inContext);
    
    DispatchContext* context = (DispatchContext*)inContext;
    NSCParameterAssert (context->queue);
    NSCParameterAssert (context->block);
    
#if PWDISPATCH_USE_QUEUEGRAPH
    PWCurrentDispatchQueueElement element;
    [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element withDispatchQueue:context->queue];
#endif

    @autoreleasepool {
        context->block();
    }
    
    Block_release ((__bridge CFTypeRef)(context->block));
    
#if PWDISPATCH_USE_QUEUEGRAPH
    [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element];
#endif

    // We need to ensure that the PWDispatchQueue instance is kept alive until the block is completed,
    // otherwise a call to PWDispatchQueue.currentQueue could result in a nil pointer when the
    // owner dropped the queue while a block is still pending or executing.
    CFRelease ((__bridge CFTypeRef)(context->queue));
    
    free (context);
}

- (void) asynchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block
{
    NSParameterAssert (block);
    dispatch_async_f ((dispatch_queue_t)impl_,
                      createAsyncDispatchContext (self, block),
                      doAsyncDispatch);
}

- (void) asynchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block
                             inGroup:(PWDispatchGroup*)group
{
    NSParameterAssert (block);
    NSParameterAssert (group);

    dispatch_group_async_f (group.underlyingGroup,
                            (dispatch_queue_t)impl_,
                            createAsyncDispatchContext (self, block),
                            doAsyncDispatch);
}

- (void) asynchronouslyDispatchAfterDelay:(NSTimeInterval)delay
                              useWallTime:(BOOL)useWallTime
                                    block:(__unsafe_unretained PWDispatchBlock)block
{
    NSParameterAssert (delay >= 0.0);
    NSParameterAssert (block);

    if(delay == 0.0)
        [self asynchronouslyDispatchBlock:block];
    else
    {
        int64_t interval = (int64_t)(delay * (double)NSEC_PER_SEC);
        dispatch_after_f (useWallTime ? dispatch_walltime(NULL, interval) : dispatch_time(0, interval),
                          (dispatch_queue_t)impl_,
                          createAsyncDispatchContext (self, block),
                          doAsyncDispatch);
    }
}

- (void) asynchronouslyDispatchAfterDate:(NSDate*)date
                                   block:(__unsafe_unretained PWDispatchBlock)block
{
    NSParameterAssert (date);
    NSParameterAssert (block);

    dispatch_after_f (PWDispatchTimeFromDate (date),
                      (dispatch_queue_t)impl_,
                      createAsyncDispatchContext (self, block),
                      doAsyncDispatch);
}

- (void) synchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block
{
    // Synchronous dispatch to a concurrent queue is possible, but I can’t see any reason to do it. Lets see how far
    // we get with disallowing it.
    NSAssert (NO, @"synchronous dispatch to concurrent queue makes no sense");
//    
//    NSParameterAssert (block);
//
//    // We want to guarantee that PWDispatchQueues can be used as recursive locks. Therefore we adopt
//    // the sloppy lock pattern described in the man page of dispatch_sync
//
//    if (self.isCurrentDispatchQueue)
//        block();
//    else
//        dispatch_sync ((dispatch_queue_t)impl_, block);
}

- (void) synchronouslyDispatchBlock:(PWApplyBlock)block times:(NSUInteger)times
{
    NSParameterAssert (block);

    dispatch_apply (times, (dispatch_queue_t)impl_, block);
}

- (void) withDispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
            dispatchBlock:(__unsafe_unretained PWDispatchBlock)block
{
    switch (dispatchKind) {
        case PWDispatchQueueDispatchKindSynchronous:
            [self synchronouslyDispatchBlock:block];
            break;
        case PWDispatchQueueDispatchKindAsynchronous:
            [self asynchronouslyDispatchBlock:block];
            break;
        case PWDispatchQueueDispatchKindDynamic:
            [self dynamicallyDispatchBlock:block];
            break;
    }
}

- (void) dynamicallyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block
{
    NSParameterAssert (block);

    if (self.isCurrentDispatchQueue)
        block();
    else
        [self asynchronouslyDispatchBlock:block];
}

- (void) asCurrentQueuePerformBlock:(PWDispatchBlock)block
{
    NSParameterAssert (block);

#if PWDISPATCH_USE_QUEUEGRAPH
    PWCurrentDispatchQueueElement element;
    [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element withDispatchQueue:self];
//    [PWDispatchQueueGraph pushInnermostCurrentDispatchQueue:self];
#endif

    block();

#if PWDISPATCH_USE_QUEUEGRAPH
    [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element];
//    [PWDispatchQueueGraph popInnermostCurrentDispatchQueue:self];
#endif
}

- (nullable NSString*) label
{
    const char* cLabel = dispatch_queue_get_label ((dispatch_queue_t)impl_);
    return cLabel ? @(cLabel) : nil;
}

- (nullable NSString*) dispatchQueueLabel
{
    return self.label;
}

- (dispatch_queue_t) underlyingQueue
{
    return (dispatch_queue_t)impl_;
}

+ (void) setMapsMainQueueToFoundation:(BOOL)map
{
    mainQueue.mapToFoundation = map;
}

+ (BOOL) mapsMainQueueToFoundation
{
    return mainQueue.mapToFoundation;
}

- (Class) dispatchTimerClass
{
    return PWDispatchTimer.class;
}

- (BOOL) isCurrentDispatchQueue
{
    NSAssert (NO, @"“is current”-test is supported for serial queues only");
    return NO;
}

@end

#pragma mark

typedef struct SerialDispatchContext
{
    __unsafe_unretained PWDispatchBlock         block;
    __unsafe_unretained PWSerialDispatchQueue*  queue;
} SerialDispatchContext;

@implementation PWSerialDispatchQueue
{
    _Atomic (pthread_t) _currentThread;
}

NS_INLINE SerialDispatchContext* createAsyncSerialDispatchContext (__unsafe_unretained PWSerialDispatchQueue* queue,
                                                                   __unsafe_unretained PWDispatchBlock block)
{
    SerialDispatchContext* context = malloc(sizeof(SerialDispatchContext));
    context->queue = CFRetain((__bridge CFTypeRef)(queue));
    context->block = (__bridge PWDispatchBlock)(Block_copy((__bridge const void *)(block)));
    return context;
}

void doAsyncSerialDispatch (void* inContext)
{
    NSCParameterAssert(inContext);
    
    SerialDispatchContext* context = (SerialDispatchContext*)inContext;
    NSCParameterAssert (context->queue);
    NSCParameterAssert (context->block);
    
#if PWDISPATCH_USE_QUEUEGRAPH
    PWCurrentDispatchQueueElement element;
    [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element withDispatchQueue:context->queue];
#endif
    
    // We want to guarantee that PWDispatchQueues can be used as recursive locks. Therefore we adopt
    // the sloppy lock pattern described in the man page of dispatch_sync
    context->queue->_currentThread = pthread_self();
    
    @autoreleasepool {
        context->block();
    }
    
    // The block needs to be released before _currentThread is reset to NULL, because the release can trigger
    // a deallocation of the block and its captured objects. Captured objects may have custom -dealloc implementations
    // which could synchronously dispatch blocks on the same queue which could not detect if the order was not
    // guaranteed in this way.
    // Note: This is the reason why we use the functional API and not use a wrapper block.
    Block_release ((__bridge CFTypeRef)(context->block));
    context->queue->_currentThread = NULL;
    
#if PWDISPATCH_USE_QUEUEGRAPH
    [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element];
#endif

    // We need to ensure that the PWDispatchQueue instance is kept alive until the block is completed,
    // otherwise a call to PWDispatchQueue.currentQueue could result in a nil pointer when the
    // owner dropped the queue while a block is still pending or executing.
    CFRelease ((__bridge CFTypeRef)(context->queue));
    
    free (context);
}

- (void) asynchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block
{
    NSParameterAssert (block);

    dispatch_async_f ((dispatch_queue_t)impl_,
                      createAsyncSerialDispatchContext(self, block),
                      doAsyncSerialDispatch);
}

- (void) asynchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block
                             inGroup:(PWDispatchGroup*)group
{
    NSParameterAssert (block);
    NSParameterAssert (group);
    
    dispatch_group_async_f (group.underlyingGroup,
                            (dispatch_queue_t)impl_,
                            createAsyncSerialDispatchContext(self, block),
                            doAsyncSerialDispatch);
}

- (void) asynchronouslyDispatchAfterDelay:(NSTimeInterval)delay
                              useWallTime:(BOOL)useWallTime
                                    block:(__unsafe_unretained PWDispatchBlock)block
{
    NSParameterAssert (delay >= 0.0);
    NSParameterAssert (block);

    if(delay == 0.0)
        [self asynchronouslyDispatchBlock:block];
    else
    {
        int64_t interval = (int64_t)(delay * (double)NSEC_PER_SEC);
        dispatch_after_f (useWallTime ? dispatch_walltime(NULL, interval) : dispatch_time(0, interval),
                          (dispatch_queue_t)impl_,
                          createAsyncSerialDispatchContext(self, block),
                          doAsyncSerialDispatch);
    }
}

- (void) asynchronouslyDispatchAfterDate:(NSDate*)date
                                   block:(__unsafe_unretained PWDispatchBlock)block
{
    NSParameterAssert (date);
    NSParameterAssert (block);
    
    dispatch_after_f (PWDispatchTimeFromDate (date),
                      (dispatch_queue_t)impl_,
                      createAsyncSerialDispatchContext(self, block),
                      doAsyncSerialDispatch);
}

void static doSyncDispatch (void* inContext)
{
    NSCParameterAssert(inContext);
    
    SerialDispatchContext* context = (SerialDispatchContext*)inContext;
    NSCParameterAssert(context->queue);
    NSCParameterAssert(context->block);
    
#if PWDISPATCH_USE_QUEUEGRAPH
    PWCurrentDispatchQueueElement element;
    [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element withDispatchQueue:context->queue];
#endif
    
    context->queue->_currentThread = pthread_self();
    context->block();
    context->queue->_currentThread = NULL;
    
#if PWDISPATCH_USE_QUEUEGRAPH
    [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element];
#endif
}

- (void) synchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block
{
    NSParameterAssert (block);
    
    // We want to guarantee that PWDispatchQueues can be used as recursive locks. Therefore we adopt
    // the sloppy lock pattern described in the man page of dispatch_sync
    
    if(self.isCurrentDispatchQueue)
        block();
    else {
    #if PWDISPATCH_USE_QUEUEGRAPH
        // Add to the graph before the actual dispatch so a cycle is found in the graph in case the dispatch deadlocks.
        [PWDispatchQueueGraph.sharedGraph addSynchronousDispatchToQueue:self];
    #endif
        
        SerialDispatchContext context;
        context.queue = self;
        context.block = block;
        dispatch_sync_f ((dispatch_queue_t)impl_,
                         &context,
                         doSyncDispatch);
    }
}

- (void) synchronouslyDispatchBlock:(PWApplyBlock)block times:(NSUInteger)times
{
    NSParameterAssert (block);
    
    dispatch_apply (times, (dispatch_queue_t)impl_, block);
}

- (void) asCurrentQueuePerformBlock:(PWDispatchBlock)block
{
    NSParameterAssert (block);
    NSAssert (_currentThread == NULL, @"queue is already current?");
    
#if PWDISPATCH_USE_QUEUEGRAPH
    PWCurrentDispatchQueueElement element;
    [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element withDispatchQueue:self];
#endif
    
    _currentThread = pthread_self();
    block();
    _currentThread = NULL;
    
#if PWDISPATCH_USE_QUEUEGRAPH
    [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element];
#endif
}

- (BOOL) isCurrentDispatchQueue
{
    pthread_t currentThread = _currentThread;
    if (currentThread == pthread_self())
        return YES;
    
    return PWDispatchDidEnterMainThreadSynchronouslyFromThread (currentThread);
}

@end

#pragma mark

@implementation PWConcurrentDispatchQueue

- (void) asynchronouslyDispatchBarrierBlock:(PWDispatchBlock)block
{
    dispatch_barrier_async ((dispatch_queue_t)impl_, ^{
        // TODO: optimize without having to use additional block (for example with functional GCD interface)
        @autoreleasepool {
            block();
        }
    });
}

- (void) synchronouslyDispatchBarrierBlock:(PWDispatchBlock)block
{
    dispatch_barrier_sync ((dispatch_queue_t)impl_, block);
}

@end

#pragma mark

inline BOOL PWDispatchDidEnterMainThreadSynchronouslyFromThread (pthread_t thread)
{
    return pthread_main_np() != 0 && thread != NULL && thread == mainQueue->_synchronouslyEnteredFromThread;
}

PWDispatchBlock PWDispatchCreateNativeAPIWrapperBlock (id<PWDispatchQueueing> queue, PWDispatchBlock clientBlock)
{
    NSCParameterAssert (queue);
    NSCParameterAssert (clientBlock);
    
    PWDispatchBlock wrapperBlock;
    
    PWDispatchQueue* dispatchQueueForNativeAPIs = queue.dispatchQueueForNativeAPIs;
    if (dispatchQueueForNativeAPIs == queue)
        // Make current queue check work for a block dispatched directly to GCD.
        wrapperBlock = ^{ [dispatchQueueForNativeAPIs asCurrentQueuePerformBlock:clientBlock]; };
    else
        wrapperBlock = ^{ [queue synchronouslyDispatchBlock:clientBlock]; };
    return [wrapperBlock copy];
}

void PWDispatchCallBlockFromNativeAPI (id<PWDispatchQueueing> queue, PWDispatchBlock clientBlock)
{
    NSCParameterAssert (queue);
    NSCParameterAssert (clientBlock);
    
    PWDispatchQueue* dispatchQueueForNativeAPIs = queue.dispatchQueueForNativeAPIs;
    if (dispatchQueueForNativeAPIs == queue)
        // Make current queue check work for a block dispatched directly to GCD.
        [dispatchQueueForNativeAPIs asCurrentQueuePerformBlock:clientBlock];
    else
        [queue synchronouslyDispatchBlock:clientBlock];
}

#ifndef NDEBUG
BOOL pwDispatchAreCurrentQueueAssertsDisabled = NO;
#endif

NS_ASSUME_NONNULL_END
