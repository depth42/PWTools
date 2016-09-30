//
//  PWDispatchMainQueue.h
//  PWFoundation
//
//  Created by Kai Brüning on 16.8.11.
//
//

#import <PWFoundation/PWDispatchQueue.h>

NS_ASSUME_NONNULL_BEGIN

/*
 Private implementation class for the PWDispatchQueue wrapper of the main dispatch queue.
 */

@interface PWDispatchMainQueue : PWDispatchQueue
{
    @package
    // The main queue is the only queue in GCD for which the thread is switched when performing a synchronous dispatch
    // from another queue. To be able to perform the -isCurrentDispatchQueue check, we need to keep book about the
    // thread from which we entered the main queue.
    volatile pthread_t _synchronouslyEnteredFromThread;
}

@property (nonatomic, readwrite)   BOOL             mapToFoundation;

@property (nonatomic, readonly)    PWDispatchQueue* timerQueue;

- (void) callBlock:(PWDispatchBlock)block;

@end

NS_ASSUME_NONNULL_END
