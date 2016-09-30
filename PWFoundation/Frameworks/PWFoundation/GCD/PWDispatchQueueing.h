//
//  PWDispatchQueueing.h
//  PWFoundation
//
//  Created by Kai Brüning on 31/08/15.
//
//

#import <PWFoundation/PWTypes.h>
#import <PWFoundation/PWDispatchObject.h> // for PWDispatchBlock

NS_ASSUME_NONNULL_BEGIN

@class PWDispatchQueue;

typedef NS_ENUM (PWInteger, PWDispatchQueueDispatchKind) {
    PWDispatchQueueDispatchKindSynchronous,
    PWDispatchQueueDispatchKindAsynchronous,
    
    // If 'queue' isCurrentDispatchQueue, the block is called synchronously, otherwise the block is queued asynchronously.
    PWDispatchQueueDispatchKindDynamic
};

@protocol PWDispatchQueueing < NSObject >

- (void) asynchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block;
- (void) asynchronouslyDispatchAfterDelay:(NSTimeInterval)delay
                              useWallTime:(BOOL)useWallTime
                                    block:(__unsafe_unretained PWDispatchBlock)block;
- (void) asynchronouslyDispatchAfterDate:(NSDate*)date block:(__unsafe_unretained PWDispatchBlock)block;

- (void) synchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block;

// If the receiver is current, the block is called synchronously, otherwise the block is queued asynchronously.
- (void) dynamicallyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block;

- (void) withDispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
            dispatchBlock:(__unsafe_unretained PWDispatchBlock)block;

// If a dispatch to the receiver did not use our wrapper (e.g. coming from NSOperationQueue) this method marks the
// receiver as current while performing block.
- (void) asCurrentQueuePerformBlock:(PWDispatchBlock)block;

@property (nonatomic, readonly)                 BOOL                isCurrentDispatchQueue;

// Native GCD APIs require a dispatch_queue_t for dispatch queue parameters. Implementations of PWDispatchQueueing
// must provide a PWDispatchQueue which wraps a native dispatch_queue_t via this property. If the implementation itself
// is a suitable PWDispatchQueue, it should return self.
// Native API wrappers receive dispatches on dispatchQueueForNativeAPIs and forward them synchronously to the passed
// in dispatch queue if necessary.
@property (nonatomic, readonly, strong)         PWDispatchQueue*    dispatchQueueForNativeAPIs;

// A text desribing this dispatch queue for debugging purposes.
@property (nonatomic, readonly, copy, nullable) NSString*           dispatchQueueLabel;

@end

NS_ASSUME_NONNULL_END
