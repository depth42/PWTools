//
//  PWDispatchSignalObserver.m
//  PWFoundation
//
//  Created by Frank Illenberger on 02.10.12.
//
//

#import "PWDispatchSignalObserver.h"
#import "PWDispatchSource-Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchSignalObserver

- (instancetype) initWithSignal:(int)signal
              onQueue:(id<PWDispatchQueueing>)queue
{
    if(self = [self initWithType:DISPATCH_SOURCE_TYPE_SIGNAL
                          handle:signal
                            mask:0
                         onQueue:queue])
    {
        _signal = signal;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
