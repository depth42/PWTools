//
//  PWDispatchMemoryPressureObserver.m
//  PWFoundation
//
//  Created by Jens Eickmeyer on 27.10.14.
//
//

#import "PWDispatchMemoryPressureObserver.h"
#import "PWDispatchSource-Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchMemoryPressureObserver

- (instancetype)initWithFlags:(dispatch_source_memorypressure_flags_t)flags
                dispatchQueue:(id<PWDispatchQueueing>)dispatchQueue
{
    NSParameterAssert(dispatchQueue);
    
    return [super initWithType:DISPATCH_SOURCE_TYPE_MEMORYPRESSURE
                        handle:0
                          mask:flags
                       onQueue:dispatchQueue];
}

@end

NS_ASSUME_NONNULL_END
