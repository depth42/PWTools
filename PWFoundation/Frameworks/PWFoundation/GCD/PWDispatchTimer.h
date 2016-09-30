//
//  PWDispatchTimer.h
//  PWFoundation
//
//  Created by Kai Brüning on 16.6.09.
//
//

#import "PWDispatchSource.h"

NS_ASSUME_NONNULL_BEGIN

@class PWDispatchQueue;


@interface PWDispatchTimer : PWDispatchSource

// Combines initWithQueue:, setEventBlock:, setStartIntervalFromNow:repetitionInterval:leeway:useWallTime: and enable
// into a single method.
+ (PWDispatchTimer*) enabledTimerWithQueue:(id<PWDispatchQueueing>)queue
                      startIntervalFromNow:(NSTimeInterval)startInterval
                        repetitionInterval:(NSTimeInterval)repetitionInterval 
                                    leeway:(NSTimeInterval)leeway
                               useWallTime:(BOOL)useWallTime
                                eventBlock:(PWDispatchBlock)handler;

// Combines initWithQueue:, setEventBlock:, setFireIntervalFromNow:leeway:useWallTime: and enable
// into a single method.
+ (PWDispatchTimer*) enabledSingleShotTimerWithQueue:(id<PWDispatchQueueing>)queue
                                 fireIntervalFromNow:(NSTimeInterval)fireInterval
                                              leeway:(NSTimeInterval)leeway
                                         useWallTime:(BOOL)useWallTime
                                          eventBlock:(PWDispatchBlock)handler;

- (instancetype) initWithQueue:(id<PWDispatchQueueing>)queue;

// Setup the timer. Can be used repeatedly to change an existing timer.
- (void) setStartIntervalFromNow:(NSTimeInterval)startInterval
              repetitionInterval:(NSTimeInterval)repetitionInterval 
                          leeway:(NSTimeInterval)leeway
                     useWallTime:(BOOL)wallTime;

// Setup for non-repeating event.
// Note: dispatch timers are always repeating. This methods simply sets the repetition interval to a very large value.
- (void) setFireIntervalFromNow:(NSTimeInterval)fireInterval
                         leeway:(NSTimeInterval)leeway
                    useWallTime:(BOOL)wallTime;

// IMPORTANT: because dispatch timers are technically always repeating, every timer must be stopped with -cancel
// when no longer needed.

// Number of times the timer has fired since the last handler invocation.
@property (nonatomic, readonly) NSUInteger fireCount;

@end

NS_ASSUME_NONNULL_END
