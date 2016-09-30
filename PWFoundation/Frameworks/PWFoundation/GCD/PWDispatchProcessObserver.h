//
//  PWDispatchProcessObserver.h
//  PWFoundation
//
//  Created by Frank Illenberger on 19.04.16.
//
//

#import <PWFoundation/PWDispatchSource.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, PWDispatchProcessEventMask)
{
    PWDispatchProcessExit   = DISPATCH_PROC_EXIT,
    PWDispatchProcessFork   = DISPATCH_PROC_FORK,
    PWDispatchProcessExec   = DISPATCH_PROC_EXEC,
    PWDispatchProcessSignal = DISPATCH_PROC_SIGNAL
};

@interface PWDispatchProcessObserver : PWDispatchSource

- (instancetype) initWithPid:(int)pid
                   eventMask:(PWDispatchProcessEventMask)eventMask
                     onQueue:(id<PWDispatchQueueing>)queue;

@property (nonatomic, readonly) int                         pid;
@property (nonatomic, readonly) PWDispatchProcessEventMask  eventMask;


@end

NS_ASSUME_NONNULL_END
