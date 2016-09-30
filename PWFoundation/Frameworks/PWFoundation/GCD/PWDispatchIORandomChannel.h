//
//  PWDispatchIORandomChannel.h
//  PWFoundation
//
//  Created by Frank Illenberger on 15.03.12.
//
//

#import <PWFoundation/PWDispatchIOChannel.h>

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchIORandomChannel : PWDispatchIOChannel
@end

@interface PWDispatchIORandomChannel (ReadingWriting)

- (void)readDispatchDataStartingFromOffset:(NSUInteger)offset
                                    length:(NSUInteger)length                 // NSNotFound means: read until EOF
                                     queue:(id<PWDispatchQueueing>)queue
                                   handler:(void (^)(BOOL done, dispatch_data_t data, NSError* errorOrNil))handler;

- (void) writeDispatchData:(dispatch_data_t)data
        startingFromOffset:(NSUInteger)offset
                     queue:(id<PWDispatchQueueing>)queue
                   handler:(void (^)(BOOL done, dispatch_data_t remainingData, NSError* errorOrNil))handler;


// Note: The following two convenience methods are for integrating with NSData objects. They are however not
// as efficient as the direct... methods because bytes need to be copied between GCD's internal data structures and
// NSData objects. If the data needs to be represented by NSData objects anyway, these two methods are fine to use.
- (void)readDataStartingFromOffset:(NSUInteger)offset
                            length:(NSUInteger)length                     // NSNotFound means: read until EOF
                             queue:(id<PWDispatchQueueing>)queue
                           handler:(void (^)(BOOL done, NSData* data, NSError* errorOrNil))handler;

- (void)writeData:(NSData*)data
startingFromOffset:(NSUInteger)offset
            queue:(id<PWDispatchQueueing>)queue
          handler:(void (^)(BOOL done, NSUInteger remainingLength, NSError* errorOrNil))handler;

@end

NS_ASSUME_NONNULL_END
