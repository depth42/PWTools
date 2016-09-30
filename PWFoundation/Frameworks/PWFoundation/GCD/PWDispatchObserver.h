//
//  PWDispatchObserver.h
//  PWFoundation
//
//  Created by Frank Illenberger on 25.07.09.
//
//

#import <PWFoundation/PWDispatchQueue.h>    // for PWDispatchQueueDispatchKind

NS_ASSUME_NONNULL_BEGIN

typedef BOOL (^PWDispatchObserverFilterBlock)(NSString* keyPath, id object);

@interface PWDispatchObserver : NSObject

- (instancetype)initWithDispatchQueue:(id<PWDispatchQueueing>)queue
                         dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind;

// Sending -dispose stops the observation and breaks any reference cycles which may exist. The message is send
// automatically when the observer is deallocated, but can be send manually for two reasons:
// - break reference cycles
// - precisely control end of observation independent e.g. of auto release cycles.
// Sub classes must make sure -dispose can be send multiple times without ill effects.
// Should be called on the same dispatch queue as the -initWithDispatchQueue:dispatchKind: was called.
// Overwrites must forward to super.
- (void)dispose;

// Can be called on any dispatch queue
- (void)disable;
- (void)enable;

// Can be called on any queue
@property (nonatomic, getter=isDisabled, readonly) BOOL disabled;

// dispatchQueue is cleared by -dispose. Always valid for undisposed observer.
@property (nonatomic, readonly, strong, nullable)   id<PWDispatchQueueing>      dispatchQueue;

@property (nonatomic, readonly)                     PWDispatchQueueDispatchKind dispatchKind;

@end

#pragma mark

@interface PWDispatchObserver (Filtering)

// Note: This category is not implemented by all dispatch observers. Currently only for deferred KV-observing.
// When provided, the filter block is called for every change and its return value decides whether the
// change should be registered to trigger a deferred call to the observer block.
// The filter block is called on the given queue, if none is given, on the queue of the managedObjectContext.
@property (nonatomic, readwrite, copy, nullable)    PWDispatchObserverFilterBlock       filterBlock;

@end

NS_ASSUME_NONNULL_END
