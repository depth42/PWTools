//
//  PWDispatchIOChannel.h
//  PWFoundation
//
//  Created by Frank Illenberger on 15.03.12.
//
//

#import <PWFoundation/PWDispatchObject.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PWDispatchQueueing;
@class PWDispatchIOChannel;

typedef void(^PWDispatchIOCleanupHandler)(PWDispatchIOChannel* blockChannel, NSError* _Nullable errorOrNil);

@interface PWDispatchIOChannel : PWDispatchObject

// The receiver retains the fileHandle until the cleanup handler has been called
// Note: So if the fileHandle is set to closeOnDealloc its underlying file descriptor may be closed
// if the file handle is not reatained by the owner or the block itself.
- (instancetype) initWithHandle:(NSFileHandle*)fileHandle
                queue:(id<PWDispatchQueueing>)queueForCleanupHandler
       cleanupHandler:(nullable PWDispatchIOCleanupHandler)cleanupHandler;

- (instancetype) initWithURL:(NSURL*)fileURL
         openFlags:(int)openFlags                               // flags passed to open() when file is opened
      creationMode:(mode_t)creationMode                         // mode passed to open() when openFlags contains O_CREAT
             queue:(id<PWDispatchQueueing>)queueForCleanupHandler
    cleanupHandler:(nullable PWDispatchIOCleanupHandler)cleanupHandler;

- (instancetype) initWithIOChannel:(PWDispatchIOChannel*)channel
                   queue:(id<PWDispatchQueueing>)queueForCleanupHandler
          cleanupHandler:(nullable PWDispatchIOCleanupHandler)cleanupHandler;

@property (nonatomic, readonly, strong, nullable)   NSFileHandle* fileHandle;       // is nil if the channel is not yet opened or if the cleanup handler has been called

@property (nonatomic, readonly)                     BOOL          isOpen;
- (void)closeImmediately:(BOOL)immediately; // If immediately==NO, all pending actions are completed

- (void)setInterval:(NSTimeInterval)value strict:(BOOL)strict;
- (void)setLowWater:(NSInteger)value;
- (void)setHighWater:(NSInteger)value;


- (void)dispatchBarrierBlock:(PWDispatchBlock)block;

#ifndef NDEBUG
// If set, slows down the performance of sending and receiving data. Only for testing purposes
@property (nonatomic, readwrite)                    NSUInteger          throttleRate;           // in bytes/s, 0 means no throttling
#endif

@end

NS_ASSUME_NONNULL_END
