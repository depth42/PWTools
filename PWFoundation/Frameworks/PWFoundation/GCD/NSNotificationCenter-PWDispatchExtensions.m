//
//  NSNotificationCenter-PWDispatchExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 25.07.09.
//
//

#import "NSNotificationCenter-PWDispatchExtensions.h"
#import "PWDispatchQueue.h"
#import "PWDispatchNotificationObserver.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSNotificationCenter (PWDispatchExtensions)

- (PWDispatchObserver*)addObserverForName:(NSString*)name
                                   object:(nullable id)object
                            dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                             dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
                               usingBlock:(PWDispatchWithNotificationBlock)block
{
    PWDispatchNotificationObserver* observer = [[PWDispatchNotificationObserver alloc] initWithDispatchQueue:queue ? queue : PWDispatchQueue.mainQueue
                                                                                               observerBlock:block
                                                                                                dispatchKind:dispatchKind
                                                                                          notificationCenter:self];
    // We do not register the observer inside PWDispatchNotificationObserver because we would have to pass in the name and object parameters
    [self addObserver:observer 
             selector:@selector(forwardNotification:) 
                 name:name
               object:object];
    return observer;
}

- (PWDispatchObserver*)addObserverForName:(NSString*)name
                                   object:(nullable id)object
                            dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                            synchronously:(BOOL)synchronous
                               usingBlock:(PWDispatchWithNotificationBlock)block
{
    return [self addObserverForName:name
                             object:object
                      dispatchQueue:queue
                       dispatchKind:synchronous ? PWDispatchQueueDispatchKindSynchronous : PWDispatchQueueDispatchKindAsynchronous
                         usingBlock:block];
}

@end

NS_ASSUME_NONNULL_END
