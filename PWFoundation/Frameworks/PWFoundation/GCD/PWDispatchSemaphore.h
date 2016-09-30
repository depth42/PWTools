//
//  PWDispatchSemaphore.h
//  PWFoundation
//
//  Created by Kai Brüning on 30.6.09.
//
//

#import <PWFoundation/PWDispatchQueue.h>

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchSemaphore : PWDispatchObject

- (instancetype) initWithInitialValue:(long)value;

- (BOOL) waitWithTimeout:(NSTimeInterval)timeout useWallTime:(BOOL)useWallTime;

- (void) waitForever;

@property (nonatomic, readonly) BOOL signal;

#if PWDISPATCH_USE_QUEUEGRAPH
// Whether this semaphore is excluded from the debug checks in PWDispatchQueueGraph.
// Should never be used without explaining why a deadlock is not possible.
@property (nonatomic, readwrite)    _Atomic(BOOL)   isExcludedFromQueueGraph;   // default is NO
#endif

@end

NS_ASSUME_NONNULL_END
