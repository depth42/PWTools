//
//  PWDispatchFIFOBuffer.h
//  Weblitz
//
//  Created by Frank Illenberger on 22.03.12.
//
//

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchFIFOBuffer : NSObject

- (void)enqueueData:(dispatch_data_t)data;

// Returns the actual dequeued length if less was available.
- (size_t)dequeueDataIntoBuffer:(void*)buffer length:(size_t)desiredLength;

@end

NS_ASSUME_NONNULL_END
