//
//  NSData-PWDispatchExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 15.03.12.
//
//

#import "NSData-PWDispatchExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSData (PWDispatchExtensions)

+ (NSData*)dataWithDispatchData:(dispatch_data_t)dispatchData
{
    NSParameterAssert(dispatchData);

#ifdef __LP64__
    // Starting with OS 10.9 & iOS 7, in 64-bit apps using either manual retain/release or ARC,
    // dispatch_data_t can now be freely cast to NSData*, though not vice versa.
    return (NSData*)dispatchData;
#else
    NSMutableData* data = [NSMutableData dataWithCapacity: dispatch_data_get_size(dispatchData)];
    dispatch_data_apply(dispatchData, ^(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
        [data appendBytes:buffer length:size];
        return (_Bool)true;
    });
    return data;
#endif
}

- (dispatch_data_t)newDispatchData
{
    return dispatch_data_create(self.bytes, self.length, NULL, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
}

@end

NS_ASSUME_NONNULL_END
