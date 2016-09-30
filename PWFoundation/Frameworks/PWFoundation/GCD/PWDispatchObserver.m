//
//  PWDispatchObserver.m
//  PWFoundation
//
//  Created by Frank Illenberger on 25.07.09.
//
//

#import "PWDispatchObserver-Private.h"
#import "PWDispatchQueue.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchObserver
{
    NSUInteger          _disableCount;
}

- (instancetype) initWithDispatchQueue:(id<PWDispatchQueueing>)queue
                          dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
{
    NSParameterAssert (queue);
    
    if(self = [super init])
    {
        _dispatchQueue   = queue;
        _dispatchKind    = dispatchKind;
        _internalQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWDispatchObserver_internal"];
    }
    return self;
}

- (void)dispose
{
    _dispatchQueue = nil;   // break retain cycles with objects posing as PWDispatchQueueing
}

- (void)dealloc
{
    // Make sure possible intermediate retains of self don’t escape the dealloc.
    @autoreleasepool {
        [self dispose];
    }
}

// TODO: We should code disable counting using atomic methods to protect against sharing accross queues, which we currently do not use

- (void)disable
{
    [_internalQueue asynchronouslyDispatchBlock:^{
        NSAssert(_disableCount < 10, @"unbalanced disable?");
        _disableCount++;
    }];
}

- (void)enable
{
    [_internalQueue asynchronouslyDispatchBlock:^{
        NSAssert(_disableCount > 0, @"unbalanced enable");
        _disableCount--;
    }];
}

- (BOOL)isDisabled
{
    __block BOOL result;
    [_internalQueue synchronouslyDispatchBlock:^{
        result = (_disableCount > 0);
    }];
    return result;
}

@end

NS_ASSUME_NONNULL_END
