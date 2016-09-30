//
//  PWDispatchMemoryPressureObserver.h
//  PWFoundation
//
//  Created by Jens Eickmeyer on 27.10.14.
//
//

#import "PWDispatchSource.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * A dispatch source that is triggered by memory pressure events signaled by the system (both OS X and iOS).
 */
@interface PWDispatchMemoryPressureObserver : PWDispatchSource

- (instancetype)initWithFlags:(dispatch_source_memorypressure_flags_t)flags
                dispatchQueue:(id<PWDispatchQueueing>)dispatchQueue;

@end

NS_ASSUME_NONNULL_END
