//
//  PWKeyedBlockQueue.h
//  PWFoundation
//
//  Created by Frank Illenberger on 16.11.12.
//
//

#import <PWFoundation/PWDispatch.h> // for PWDispatchBlock

NS_ASSUME_NONNULL_BEGIN

// The action queue can postpone actions as long as it is suspended.
@interface PWKeyedBlockQueue : NSObject

- (void)dispose;

// If the queue is not suspended, the block is performed immediately, 
// otherwise it is queued, but only once for each key.
- (void)forKey:(NSString*)key performBlock:(PWDispatchBlock)block;

// Performs the block which has been queued via -performAction and removes it from the queue.
- (void)performPendingBlockForKey:(NSString*)key;

// Suspending the queue disables the immediate peforming in -forKey:performBlock:
// Nests with calls to -resume.
- (void)suspend;

// Resuming the queue immediately performs all queued selectors in the order in which they were queued first.
- (void)resume;

@property (nonatomic, readonly) BOOL isSuspended;

@end

NS_ASSUME_NONNULL_END
