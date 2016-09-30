//
//  PWDispatchPathObserver.h
//  PWFoundation
//
//  Created by Frank Illenberger on 06.04.16.
//
//

#import <PWFoundation/PWDispatchFileObserver.h>

NS_ASSUME_NONNULL_BEGIN

// Observes all segments of the path of the given URL.
@interface PWDispatchPathObserver : NSObject

- (instancetype)initWithFileURL:(NSURL*)URL
                      eventMask:(PWDispatchFileEventMask)mask
                        onQueue:(id<PWDispatchQueueing>)queue
                     eventBlock:(PWDispatchBlock)eventBlock;

- (void)enable;

- (void)disable;

- (void)dispose;

@property (nonatomic, readonly)                     PWDispatchFileEventMask    eventMask;
@property (nonatomic, readonly, copy, nullable)     NSURL*                     URL;         // nil for -initWithFileHandle:...

@end

NS_ASSUME_NONNULL_END
