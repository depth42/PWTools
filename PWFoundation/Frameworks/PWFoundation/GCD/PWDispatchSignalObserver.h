//
//  PWDispatchSignalObserver.h
//  PWFoundation
//
//  Created by Frank Illenberger on 02.10.12.
//
//

#import <PWFoundation/PWDispatchSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchSignalObserver : PWDispatchSource

- (instancetype) initWithSignal:(int)signal                   // UNIX signal constant like SIGTERM, SIGHUP etc.
              onQueue:(id<PWDispatchQueueing>)queue;

@property (nonatomic, readonly)  int signal;
@end

NS_ASSUME_NONNULL_END
