//
//  PWDispatchIORandomChannel.m
//  PWFoundation
//
//  Created by Frank Illenberger on 15.03.12.
//
//

#import "PWDispatchIORandomChannel.h"
#import "PWDispatchIOChannel-Private.h"
#import "PWDispatchQueue.h"
#import "PWDispatchObject-Internal.h"
#import "NSData-PWDispatchExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchIORandomChannel

// Override from PWDispatchIOChannel
- (dispatch_io_type_t)dispatchIOType
{
    return DISPATCH_IO_RANDOM;
}

@end

NS_ASSUME_NONNULL_END
