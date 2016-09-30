//
//  PWDispatchQueueingHelper.h
//  PWFoundation
//
//  Created by Kai Brüning on 2/09/15.
//
//

#import <PWFoundation/PWDispatchObject.h>
#import <PWFoundation/PWDispatchQueueing.h>

NS_ASSUME_NONNULL_BEGIN

/*
 Helper class for implementing PWDispatchQueueing outside of PWDispatchQueue.
 
 Instances keep track of the "is current dispatch queue" state.
 
 As a convenience, a dispatch queue is kept for use as PWDispatchQueueing.dispatchQueueForNativeAPIs.
 This queue is allocated on demand, protected by dispatch_once().
 */

@interface PWDispatchQueueingHelper : NSObject

- (instancetype) initWithLabel:(nullable NSString*)label NS_DESIGNATED_INITIALIZER;

// The implemementation of -[PWDispatchQueueing synchronouslyDispatchBlock:] needs to dispatch a wrapper block which
// then calls this method with the original block.
- (void) callSynchronouslyDispatchedBlock:(__unsafe_unretained PWDispatchBlock)block;

// Same as above for asynchronous dispatch.
// The lifetime of asynchronously dispatched blocks must be carefully controlled to ensure that deallocations happen
// while the dispatching queue is still marked as current (see comment in .m).
// The pattern for implementing -asynchronouslyDispatchBlock: is as follows:
//
// - (void) asynchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block {
//    __block PWDispatchBlock originalBlock = [block copy];
//
//    [do asynchronous dispatch of block:^{
//        [_dispatchQueueingHelper callAsynchronouslyDispatchedBlock:&originalBlock];
//    }];
// }
// This pattern allows -callAsynchronouslyDispatchedBlock: to release the block by setting *inOutBlock to nil at the
// right time.
- (void) callAsynchronouslyDispatchedBlock:(PWDispatchBlock __strong _Nullable *_Nonnull)inOutBlock;

// Can be called from any queue.
@property (nonatomic, readonly)                 BOOL                isCurrentDispatchQueue;

// Can be called from any queue.
@property (nonatomic, readonly, strong)         PWDispatchQueue*    dispatchQueueForNativeAPIs;

// Invaraint, can be called from any queue.
@property (nonatomic, readonly, copy, nullable) NSString*           dispatchQueueLabel;

@end

NS_ASSUME_NONNULL_END
