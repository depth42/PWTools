//
//  PWDispatchQueue-Private.h
//  PWFoundation
//
//  Created by Kai Brüning on 16.8.11.
//
//

#import <PWFoundation/PWDispatchQueue.h>
#import "pthread.h"

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchQueue ()

- (instancetype) initWithUnderlyingObject:(dispatch_object_t)anImpl;

@property (nonatomic, readonly) Class dispatchTimerClass;

@end

#pragma mark

@interface PWSerialDispatchQueue : PWDispatchQueue
@end

#ifdef __cplusplus
extern "C" {
#endif
    
    // The main queue is the only queue in GCD for which the thread is switched when performing a synchronous dispatch
    // from another queue. To be able to perform the -isCurrentDispatchQueue check in non-main queues, the main queue
    // keeps book about the thread from which it was synchronously entered.
    BOOL PWDispatchDidEnterMainThreadSynchronouslyFromThread (pthread_t thread);

#ifdef __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
