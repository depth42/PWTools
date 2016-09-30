//
//  PWDispatchQueue.h
//  PWFoundation
//
//  Created by Kai Brüning on 15.6.09.
//
//

#ifndef PWDISPATCH_USE_QUEUEGRAPH
    #ifdef NS_BLOCK_ASSERTIONS
        #define PWDISPATCH_USE_QUEUEGRAPH 0
    #else
        #define PWDISPATCH_USE_QUEUEGRAPH 1
    #endif
#endif

#import <PWFoundation/PWDispatchObject.h>
#import <PWFoundation/PWDispatchQueueing.h>

NS_ASSUME_NONNULL_BEGIN

@class PWConcurrentDispatchQueue;
@class PWDispatchGroup;

@interface PWDispatchQueue : PWDispatchObject < PWDispatchQueueing >

+ (PWDispatchQueue*) mainQueue;
+ (PWDispatchQueue*) globalDefaultPriorityQueue;
+ (PWDispatchQueue*) globalLowPriorityQueue;
+ (PWDispatchQueue*) globalHighPriorityQueue;

// Factory methods for dispatch queues. May return private sub classes.
+ (PWDispatchQueue*) serialDispatchQueueWithLabel:(nullable NSString*)label;
+ (PWConcurrentDispatchQueue*) concurrentDispatchQueueWithLabel:(nullable NSString*)label;

- (void) asynchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block;
- (void) asynchronouslyDispatchAfterDelay:(NSTimeInterval)delay
                              useWallTime:(BOOL)useWallTime
                                    block:(__unsafe_unretained PWDispatchBlock)block;
- (void) asynchronouslyDispatchAfterDate:(NSDate*)date block:(__unsafe_unretained PWDispatchBlock)block;

// Note: this method is never mapped to Foundation by the main queue.
- (void) asynchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block inGroup:(PWDispatchGroup*)group;

- (void) synchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block;

- (void) withDispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
            dispatchBlock:(__unsafe_unretained PWDispatchBlock)block;

// Note: this method is never mapped to Foundation by the main queue.
- (void) synchronouslyDispatchBlock:(PWApplyBlock)block times:(NSUInteger)times;

// If the receiver isCurrentDispatchQueue, the block is called synchronously, otherwise the block is queued asynchronously
- (void) dynamicallyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block;

// If a dispatch to the receiver did not use our wrapper (e.g. coming from NSOperationQueue) this method marks the
// receiver as current while performing block.
- (void) asCurrentQueuePerformBlock:(PWDispatchBlock)block;

@property (nonatomic, readonly, nullable)   NSString*           label;
@property (nonatomic, readonly)             dispatch_queue_t    underlyingQueue;
@property (nonatomic, readonly)             BOOL                isCurrentDispatchQueue;

+ (void) setMapsMainQueueToFoundation:(BOOL)map;
+ (BOOL) mapsMainQueueToFoundation;

@end

#pragma mark

@interface PWConcurrentDispatchQueue : PWDispatchQueue

- (void) asynchronouslyDispatchBarrierBlock:(PWDispatchBlock)block;

- (void) synchronouslyDispatchBarrierBlock:(PWDispatchBlock)block;

@end

#pragma mark

#ifdef __cplusplus
extern "C" {
#endif

    // To use 'queue' with an API which does not use our wrappers, pass the block returned from this function to
    // the API and use queue.dispatchQueueForNativeAPIs.underlyingQueue as GCD queue.
    PWDispatchBlock PWDispatchCreateNativeAPIWrapperBlock (id<PWDispatchQueueing> queue, PWDispatchBlock clientBlock);

    // For native APIs which use blocks with custom signatures (anything but void(^)()). Call this function from the
    // block passed to the API and pass as 'clientBlock' a block which captures and forwards the block parameters.
    void PWDispatchCallBlockFromNativeAPI (id<PWDispatchQueueing> queue, PWDispatchBlock clientBlock);

#ifndef NDEBUG
    // This global allows to temporarily disable asserting the correct current queue. Useful for methods which are
    // typically called from the debugger console.
    extern BOOL pwDispatchAreCurrentQueueAssertsDisabled;
#endif

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
