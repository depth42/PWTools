//
//  PWDispatchQueueingHelper.m
//  PWFoundation
//
//  Created by Kai Brüning on 2/09/15.
//
//

#import "PWDispatchQueueingHelper.h"
#import "PWDispatchQueue-Private.h"
#import "PWDispatchQueueGraph.h"
#import "pthread.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchQueueingHelper
{
    _Atomic (pthread_t) _currentThread;
    dispatch_once_t     _dispatchQueueForNativeAPIsPredicate;
}

- (instancetype) initWithLabel:(nullable NSString*)label
{
    if ((self = [super init]) != nil) {
        _dispatchQueueLabel = [label copy];
    }
    return self;
}

- (instancetype) init
{
    return [self initWithLabel:nil];
}

#if PWDISPATCH_USE_QUEUEGRAPH
- (void) dealloc
{
    [PWDispatchQueueGraph.sharedGraph removeDispatchObject:self];
}
#endif

- (void) callSynchronouslyDispatchedBlock:(__unsafe_unretained PWDispatchBlock)block
{
    NSParameterAssert (block);
    
#if PWDISPATCH_USE_QUEUEGRAPH
    PWCurrentDispatchQueueElement element;
    [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element withDispatchQueue:(id)self];
#endif

    // We want to guarantee that PWDispatchQueues can be used as recursive locks. Therefore we adopt
    // the sloppy lock pattern described in the man page of dispatch_sync
    _currentThread = pthread_self();
    block();
    _currentThread = NULL;

#if PWDISPATCH_USE_QUEUEGRAPH
    [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element];
#endif
}

- (void) callAsynchronouslyDispatchedBlock:(PWDispatchBlock __strong _Nullable *_Nonnull)inOutBlock
{
    NSParameterAssert (inOutBlock);
    NSParameterAssert (*inOutBlock);
    
#if PWDISPATCH_USE_QUEUEGRAPH
    PWCurrentDispatchQueueElement element;
    [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element withDispatchQueue:(id)self];
#endif

    // We want to guarantee that PWDispatchQueues can be used as recursive locks. Therefore we adopt
    // the sloppy lock pattern described in the man page of dispatch_sync
    _currentThread = pthread_self();
    
    @autoreleasepool {
        (*inOutBlock)();
        *inOutBlock = nil;
    }
    
    // The passed in block needs to be released before _currentThread is reset to NULL, because the release can trigger
    // a deallocation of the block and its captured objects. Captured objects may have custom -dealloc implementations
    // which could synchronously dispatch blocks on the same queue which could not be detected if the order was not
    // guaranteed in this way.
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
    
    // The main queue is the only queue in GCD for which the thread is switched when
    // performing a synchronous dispatch from another queue. To be able to perform the
    // -isCurrentDispatchQueue check in non-main queues, the main queue keeps book about the thread from which
    // it was synchronously entered.
    return PWDispatchDidEnterMainThreadSynchronouslyFromThread (currentThread);
}

@synthesize dispatchQueueForNativeAPIs = _dispatchQueueForNativeAPIs;

- (PWDispatchQueue*) dispatchQueueForNativeAPIs
{
    dispatch_once (&_dispatchQueueForNativeAPIsPredicate, ^{
        NSString* label = [NSString stringWithFormat:@"Native API Queue for %@", self.dispatchQueueLabel];
        _dispatchQueueForNativeAPIs = [PWDispatchQueue serialDispatchQueueWithLabel:label];
    });
    return _dispatchQueueForNativeAPIs;
}

@end

NS_ASSUME_NONNULL_END
