//
//  PWDispatchIOStreamChannel.h
//  PWFoundation
//
//  Created by Frank Illenberger on 15.03.12.
//
//

#import <PWFoundation/PWDispatchIOChannel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PWOutputStream <NSObject>
- (void)writeDispatchData:(dispatch_data_t)data
                    queue:(id<PWDispatchQueueing>)queue
                  handler:(void (^)(BOOL done, dispatch_data_t _Nullable remainingData, NSError* _Nullable error))handler;

- (void)writeData:(NSData*)data
            queue:(id<PWDispatchQueueing>)queue
          handler:(void (^)(BOOL done, NSUInteger remainingLength, NSError* _Nullable error))handler;

// Key-Value observable
@property (nonatomic, readonly) BOOL isOpen;

- (void)closeImmediately:(BOOL)immediately; // If immediately==NO, all pending actions are completed
@end



@interface PWDispatchIOStreamChannel : PWDispatchIOChannel
@end


@interface PWDispatchIOStreamChannel (ReadingWriting) <PWOutputStream>

- (void)readDispatchDataWithLength:(NSUInteger)length
                             queue:(id<PWDispatchQueueing>)queue
                           handler:(void (^)(BOOL done, dispatch_data_t _Nullable data, NSError* _Nullable error))handler;

// Note: The following two convenience methods are for integrating with NSData objects. They are however not
// as efficient as the direct... methods because bytes need to be copied between GCD's internal data structures and
// NSData objects. If the data needs to be represented by NSData objects anyway, these two methods are fine to use.
- (void)readDataWithLength:(NSUInteger)length                // NSNotFound means: read until EOF
                     queue:(id<PWDispatchQueueing>)queue
                   handler:(void (^)(BOOL done, NSData* _Nullable data, NSError* _Nullable error))handler;

// Copies "length" bytes of data from the receiver to the target stream
- (void)copyDataWithLength:(NSUInteger)length          // if length == NSNotFound, copies until EOF is reached
          inChunksOfLength:(NSUInteger)chunkLength     // Has to be greater than zero
                  toStream:(id <PWOutputStream>)targetStream
                     queue:(id<PWDispatchQueueing>)queue     // if nil, current queue is used
           progressHandler:(nullable void (^)(NSUInteger writtenLength))progressHandler
         completionHandler:(nullable void (^)(NSUInteger writtenLength, NSError* _Nullable error))completionHandler;

@end

NS_ASSUME_NONNULL_END
