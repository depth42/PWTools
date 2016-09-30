//
//  NSNotificationCenter-PWDispatchExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 25.07.09.
//
//

#import <PWFoundation/PWDispatchQueue.h>    // for PWDispatchQueueDispatchKind

NS_ASSUME_NONNULL_BEGIN

@class PWDispatchQueue;
@class PWDispatchObserver;

typedef void(^PWDispatchWithNotificationBlock)(NSNotification* notification);

@interface NSNotificationCenter (PWDispatchExtensions)

- (PWDispatchObserver*)addObserverForName:(NSString*)name
                                   object:(nullable id)object
                            dispatchQueue:(nullable id<PWDispatchQueueing>)queue    // nil -> main queue
                             dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
                               usingBlock:(PWDispatchWithNotificationBlock)block;

// OBSOLETE, forwards to above.
- (PWDispatchObserver*)addObserverForName:(NSString*)name
                                   object:(nullable id)object 
                            dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                            synchronously:(BOOL)synchronous
                               usingBlock:(PWDispatchWithNotificationBlock)block;

@end

NS_ASSUME_NONNULL_END
