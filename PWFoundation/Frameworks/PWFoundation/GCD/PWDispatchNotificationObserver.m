//
//  PWDispatchNotificationObserver.m
//  PWFoundation
//
//  Created by Andreas Känner on 8/11/09.
//
//

#import "PWDispatchNotificationObserver.h"
#import "PWDispatchObserver-Private.h"
#import "PWDispatchQueue.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchNotificationObserver
{
#ifndef NDEBUG
    BOOL    _disposed;
#endif
}

- (instancetype)initWithDispatchQueue:(id<PWDispatchQueueing>)queue
                        observerBlock:(PWDispatchNotificationBlock)block
                         dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
                   notificationCenter:(NSNotificationCenter*)notificationCenter
{
    NSParameterAssert(block);

    if(self = [super initWithDispatchQueue:queue dispatchKind:dispatchKind])
    {
        _observerBlock = [block copy];
        _notificationCenter = notificationCenter;
    }
    return self;
}

- (void)forwardNotification:(NSNotification*)notification
{
    if(!self.isDisabled)
        [self.dispatchQueue withDispatchKind:self.dispatchKind
                               dispatchBlock:^
         {
             __block PWDispatchNotificationBlock observerBlock;
             [self.internalQueue synchronouslyDispatchBlock:^{
                 observerBlock = _observerBlock;
             }];
             if(observerBlock)
                 observerBlock(notification);
         }];
}

- (void)dispose
{
    __block PWDispatchNotificationBlock observerBlock;

    [self.internalQueue synchronouslyDispatchBlock:^
     {
         observerBlock = _observerBlock;    // Make sure that dealloc of observerBlock is done on the dispatch queue of the caller
         _observerBlock = nil;
     }];

    if(observerBlock)
        [_notificationCenter removeObserver:self];
    
    [super dispose];

#ifndef NDEBUG
    _disposed = YES;
#endif
}

@end

NS_ASSUME_NONNULL_END
