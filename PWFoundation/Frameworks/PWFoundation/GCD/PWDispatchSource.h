//
//  PWDispatchSource.h
//  PWFoundation
//
//  Created by Kai Brüning on 16.6.09.
//
//

#import "PWDispatchObject.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PWDispatchQueueing;

/*
 PWDispatchSource is an abstract class, only concrete sub classes (currently PWDispatchTimer, PWDispatchFileObserver,
 PWDispatchFileWriter, PWDispatchFileReader, PWDispatchSignalObserver and PWDispatchMemoryPressureObserver) are to be
 instanciated.
 
 Dispatch sources are created disabled and must receive an -enable message to take action.
 */

@interface PWDispatchSource : PWDispatchObject

- (void) setEventBlock:(nullable PWDispatchBlock)handler;

- (void) setCancelBlock:(nullable PWDispatchBlock)handler;

- (void) cancel;

@property (nonatomic, readonly, strong) id<PWDispatchQueueing>  queue;
@property (nonatomic, readonly)         BOOL                    isCancelled;
@property (nonatomic, readonly)         dispatch_source_t       underlyingSource;

@end

NS_ASSUME_NONNULL_END
