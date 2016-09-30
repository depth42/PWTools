//
//  PWDispatchMainQueueTimer.m
//  PWFoundation
//
//  Created by Torsten Radtke on 05.12.13.
//
//

#import "PWDispatchMainQueueTimer.h"

#import "PWDispatchTimer-Private.h"
#import "PWDispatchMainQueue.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchMainQueueTimer

// Overwritten from PWDispatchTimer.
- (id) initPrivateWithQueue:(id<PWDispatchQueueing>)queue
{
    NSParameterAssert(queue);
    NSParameterAssert(queue == PWDispatchQueue.mainQueue);
    
    PWDispatchQueue* timerQueue = ((PWDispatchMainQueue*)queue).timerQueue;
    return [super initPrivateWithQueue:timerQueue];
}

// Overwritten from PWDispatchTimer.
- (void) setEventBlock:(nullable PWDispatchBlock)handler
{
    // Note: No copy on the handler is necessary as it is copied during the capturing of the outer block.
    
    [super setEventBlock:^() {
        [PWDispatchQueue.mainQueue performSelectorOnMainThread:@selector(callBlock:)
                                                    withObject:handler
                                                 waitUntilDone:NO
                                                         modes:@[NSRunLoopCommonModes]];
    }];
}

@end

NS_ASSUME_NONNULL_END
