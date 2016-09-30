//
//  PWDispatchSource-Internal.h
//  PWFoundation
//
//  Created by Kai Brüning on 16.6.09.
//
//

#import "PWDispatchSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchSource (Private)

- (id) initWithType:(dispatch_source_type_t)type
             handle:(uintptr_t)handle
               mask:(NSUInteger)mask
            onQueue:(id<PWDispatchQueueing>)queue;

@property (nonatomic, readonly)    unsigned long       data;

@end

NS_ASSUME_NONNULL_END
