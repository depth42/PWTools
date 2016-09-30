//
//  PWDispatchTimer-Private.h
//  PWFoundation
//
//  Created by Kai Brüning on 16.8.11.
//
//

#import "PWDispatchTimer.h"

NS_ASSUME_NONNULL_BEGIN

@class PWDispatchQueue;


@interface PWDispatchTimer ()

- (id) initPrivateWithQueue:(id<PWDispatchQueueing>)queue;

- (id) initAndEnableWithQueue:(id<PWDispatchQueueing>)queue
         startIntervalFromNow:(NSTimeInterval)startInterval
           repetitionInterval:(NSTimeInterval)repetitionInterval 
                       leeway:(NSTimeInterval)leeway
                  useWallTime:(BOOL)useWallTime
                   eventBlock:(PWDispatchBlock)handler;

- (id) initAndEnableWithQueue:(id<PWDispatchQueueing>)queue
          fireIntervalFromNow:(NSTimeInterval)fireInterval
                       leeway:(NSTimeInterval)leeway
                  useWallTime:(BOOL)useWallTime
                   eventBlock:(PWDispatchBlock)handler;

@end

NS_ASSUME_NONNULL_END
