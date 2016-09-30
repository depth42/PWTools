//
//  NSObject-PWDispatchExtensions.h
//  PWFoundation
//
//  Created by Andreas Känner on 8/11/09.
//
//

#import <PWFoundation/PWEnumerable.h>
#import <PWFoundation/PWDispatchObject.h>           // for PWDispatchBlock
#import <PWFoundation/PWDispatchQueueing.h>
#import <PWFoundation/PWDelayedPerformMomentRestriction.h>

NS_ASSUME_NONNULL_BEGIN

@class PWDispatchQueue;
@class PWDispatchObserver;
@class PWManagedObjectContext;

typedef void(^PWDispatchObserverBlock)(NSString* keyPath, id obj, NSDictionary* change);

@interface NSObject (PWDispatchExtensions)

// IMPORTANT: the observer instance returned by the following methods remembers the observed object(s) unsafe_unretained
// and uses these pointers to remove the observation in -dispose.
// Holders of observers are required to dispose them while the observed objects are still alive.
// See PWDispatchKeyValueObserver.mm why they are not kept as weak references.
// Note that this matches Apples pattern for key value observing.

// nil for queue uses the main queue.

- (PWDispatchObserver*)addObserverForKeyPaths:(id <PWEnumerable>)keyPaths
                                      options:(NSKeyValueObservingOptions)options
                                dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                                 dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
                                   usingBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block;

+ (nullable PWDispatchObserver*)observeKeyPaths:(id <PWEnumerable>)keyPaths      // if nil or elementCount == 0, a nil observer is returned
                                      ofObjects:(id <PWEnumerable>)objects       // if nil or elementCount == 0, a nil observer is returned
                                        options:(NSKeyValueObservingOptions)options
                                  dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                                   dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
                                     usingBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block;

// OBSOLETE variants, forward to above with dispatchKind.
- (nullable PWDispatchObserver*)addObserverForKeyPaths:(id <PWEnumerable>)keyPaths
                                               options:(NSKeyValueObservingOptions)options
                                         dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                                         synchronously:(BOOL)synchronous
                                            usingBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block;

- (nullable PWDispatchObserver*)addObserverForKeyPath:(NSString*)keyPath
                                              options:(NSKeyValueObservingOptions)options
                                        dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                                        synchronously:(BOOL)synchronous
                                           usingBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block;

+ (nullable PWDispatchObserver*)observeKeyPaths:(id <PWEnumerable>)keyPaths
                                      ofObjects:(id <PWEnumerable>)objects
                                        options:(NSKeyValueObservingOptions)options
                                  dispatchQueue:(nullable id<PWDispatchQueueing>)queue
                                  synchronously:(BOOL)synchronous
                                     usingBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block;

- (void)afterDelay:(NSTimeInterval)delay performBlock:(PWDispatchBlock)block;
- (void)afterDelay:(NSTimeInterval)delay inModes:(NSArray*)modes performBlock:(PWDispatchBlock)block;

@end

NS_ASSUME_NONNULL_END
