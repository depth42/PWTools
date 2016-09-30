//
//  NSData-PWDispatchExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 15.03.12.
//
//

#import <dispatch/dispatch.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (PWDispatchExtensions)

+ (NSData*)dataWithDispatchData:(dispatch_data_t)dispatchData;      // on 32bit systems, buffer gets copied
@property (nonatomic, readonly, strong) dispatch_data_t _Nonnull newDispatchData;                                 // buffer gets copied, needs to be released by caller

@end

NS_ASSUME_NONNULL_END
