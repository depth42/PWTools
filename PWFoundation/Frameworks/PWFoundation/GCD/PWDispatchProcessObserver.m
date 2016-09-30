//
//  PWDispatchProcessObserver.m
//  PWFoundation
//
//  Created by Frank Illenberger on 19.04.16.
//
//

#import "PWDispatchProcessObserver.h"
#import "PWDispatchSource-Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchProcessObserver

- (instancetype) initWithPid:(int)pid
                   eventMask:(PWDispatchProcessEventMask)eventMask
                     onQueue:(id<PWDispatchQueueing>)queue
{
    self = [self initWithType:DISPATCH_SOURCE_TYPE_PROC
                       handle:pid
                         mask:eventMask
                      onQueue:queue];
    _pid = pid;
    _eventMask = eventMask;
    return self;
}

@end

NS_ASSUME_NONNULL_END
