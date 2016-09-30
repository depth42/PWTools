//
//  PWDispatchIOChannel-Private.h
//  PWFoundation
//
//  Created by Frank Illenberger on 15.03.12.
//
//

#import <PWFoundation/PWDispatchIOChannel.h>

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchIOChannel (Private)

- (void)readDispatchDataStartingFromOffset:(NSUInteger)offset
                                    length:(NSUInteger)length
                                     queue:(id<PWDispatchQueueing>)queue
                                   handler:(void (^)(BOOL done, dispatch_data_t _Nullable data, NSError* _Nullable errorOrNil))handler;

- (void) writeDispatchData:(dispatch_data_t)data
        startingFromOffset:(NSUInteger)offset
                     queue:(nullable id<PWDispatchQueueing>)queue
                   handler:(nullable void (^)(BOOL done, dispatch_data_t _Nullable remainingData, NSError* _Nullable errorOrNil))handler;

- (void)readDataStartingFromOffset:(NSUInteger)offset
                            length:(NSUInteger)length
                             queue:(id<PWDispatchQueueing>)queue
                           handler:(void (^)(BOOL done, NSData* _Nullable data, NSError* _Nullable errorOrNil))handler;

- (void) writeData:(NSData*)data
startingFromOffset:(NSUInteger)offset
             queue:(id<PWDispatchQueueing>)queue
           handler:(nullable void (^)(BOOL done, NSUInteger remainingLength, NSError* _Nullable errorOrNil))handler;

@property (nonatomic, readonly) dispatch_io_type_t dispatchIOType;

@end

NS_ASSUME_NONNULL_END
