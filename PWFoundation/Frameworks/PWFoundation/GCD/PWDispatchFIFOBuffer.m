//
//  PWDispatchFIFOBuffer.m
//  Weblitz
//
//  Created by Frank Illenberger on 22.03.12.
//
//

#import "PWDispatchFIFOBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchFIFOBuffer
{
    dispatch_data_t dataQueue_;
}

- (void)enqueueData:(dispatch_data_t)data
{
    NSParameterAssert(data && dispatch_data_get_size(data) > 0);
    
    if(!dataQueue_)
        dataQueue_ = data;
    else
    {
        dispatch_data_t newData = dispatch_data_create_concat(dataQueue_, data);
        dataQueue_ = newData;
    }
}

// Returns the actual dequeued length if less was available.
- (size_t)dequeueDataIntoBuffer:(void*)buffer length:(size_t)desiredLength
{
    NSParameterAssert(buffer);
    NSParameterAssert(desiredLength > 0);
    
    size_t availableLength = dataQueue_ ? dispatch_data_get_size(dataQueue_) : 0;
    if(availableLength == 0)
        return 0;
    
    size_t length = MIN(desiredLength, availableLength);
    NSAssert(dataQueue_, nil);
    __block size_t remainingLength = length;
    __block void* iBuffer = buffer;
    dispatch_data_apply(dataQueue_, ^bool(dispatch_data_t region, size_t offset, const void* regionBuffer, size_t regionLength) {
        size_t lengthToCopy = MIN(remainingLength, regionLength);
        NSCAssert(iBuffer + lengthToCopy <= buffer + length, nil);
        memcpy(iBuffer, regionBuffer, lengthToCopy);
        iBuffer += lengthToCopy;
        NSCAssert(remainingLength >= lengthToCopy, nil);
        remainingLength -= lengthToCopy;
        return remainingLength > 0;
    });
    
    if(availableLength == length)
    {
        dataQueue_ = NULL;
    }
    else {
        NSAssert(availableLength > length, nil);
        dispatch_data_t newData = dispatch_data_create_subrange(dataQueue_, length, availableLength - length);
        dataQueue_ = newData;
    }
    return length;
}

@end

NS_ASSUME_NONNULL_END
