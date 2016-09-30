//
//  PWDispatchNotificationObserver.h
//  PWFoundation
//
//  Created by Andreas Känner on 8/11/09.
//
//

#import "PWDispatchObserver.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^PWDispatchNotificationBlock)(NSNotification* notification);

@interface PWDispatchNotificationObserver : PWDispatchObserver

- (instancetype)initWithDispatchQueue:(id<PWDispatchQueueing>)queue
                        observerBlock:(PWDispatchNotificationBlock)block
                         dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
                   notificationCenter:(NSNotificationCenter*)notificationCenter;

- (void)forwardNotification:(NSNotification*)notification;

@property (nonatomic, readonly, copy, nullable) PWDispatchNotificationBlock    observerBlock;   // nil after dispose
@property (nonatomic, readonly, strong)         NSNotificationCenter*          notificationCenter;

@end

NS_ASSUME_NONNULL_END
