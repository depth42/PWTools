//
//  PWDispatchIOStreamChannel.m
//  PWFoundation
//
//  Created by Frank Illenberger on 15.03.12.
//
//

#import "PWDispatchIOStreamChannel.h"
#import "PWDispatchIOChannel-Private.h"
#import "PWDispatchQueue.h"
#import "PWDispatchObject-Internal.h"
#import "NSData-PWDispatchExtensions.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchIOStreamChannel

// Override from PWDispatchIOChannel
- (dispatch_io_type_t)dispatchIOType
{
    return DISPATCH_IO_STREAM;
}

- (void)readDispatchDataWithLength:(NSUInteger)length
                             queue:(id<PWDispatchQueueing>)queue
                           handler:(void (^)(BOOL done, dispatch_data_t _Nullable data, NSError* _Nullable error))handler
{
    [self readDispatchDataStartingFromOffset:0 length:length queue:queue handler:handler];
}

- (void)writeDispatchData:(dispatch_data_t)data
                    queue:(id<PWDispatchQueueing>)queue
                  handler:(void (^)(BOOL done, dispatch_data_t _Nullable remainingData, NSError* _Nullable error))handler
{
    [self writeDispatchData:data startingFromOffset:0 queue:queue handler:handler];
}

- (void)readDataWithLength:(NSUInteger)length
                     queue:(id<PWDispatchQueueing>)queue
                   handler:(void (^)(BOOL done, NSData* _Nullable data, NSError* _Nullable error))handler
{
    [self readDataStartingFromOffset:0 length:length queue:queue handler:handler];   
}

- (void)writeData:(NSData*)data
            queue:(id<PWDispatchQueueing>)queue
          handler:(void (^)(BOOL done, NSUInteger remainingLength, NSError* _Nullable error))handler
{
    [self writeData:data startingFromOffset:0 queue:queue handler:handler];
}

- (void)copyDataWithLength:(NSUInteger)length          // if length == NSNotFound, copies until EOF is reached
          inChunksOfLength:(NSUInteger)chunkLength
                  toStream:(id <PWOutputStream>)targetStream
                     queue:(id<PWDispatchQueueing>)queue
           progressHandler:(nullable void (^)(NSUInteger writtenLength))progressHandler
         completionHandler:(nullable void (^)(NSUInteger writtenLength, NSError* _Nullable error))completionHandler
{
    NSParameterAssert(length > 0);
    NSParameterAssert(chunkLength > 0);
    NSParameterAssert(targetStream);
    NSParameterAssert(queue);

    [self setLowWater:chunkLength];
    [self setHighWater:chunkLength];
    [queue asynchronouslyDispatchBlock:^{
        [self doCopyDataWithLength:length 
                  inChunksOfLength:chunkLength
                          toStream:targetStream 
                     writtenLength:0
                             queue:queue
                   progressHandler:progressHandler
                 completionHandler:completionHandler];
    }];
}    

- (void)doCopyDataWithLength:(NSUInteger)length
            inChunksOfLength:(NSUInteger)chunkLength
                    toStream:(id <PWOutputStream>)targetStream
               writtenLength:(NSUInteger)writtenLength
                       queue:(id<PWDispatchQueueing>)queue
             progressHandler:(nullable void (^)(NSUInteger writtenLength))progressHandler
           completionHandler:(nullable void (^)(NSUInteger writtenLength, NSError *_Nullable error))completionHandler
{
    NSParameterAssert(length == NSNotFound || writtenLength < length);
    NSParameterAssert(chunkLength > 0);
    NSParameterAssert(targetStream);
    NSParameterAssert(queue);
    NSParameterAssert(queue.isCurrentDispatchQueue);
    
    if(length != NSNotFound)
        chunkLength = MIN(length - writtenLength, chunkLength);
    
    __block NSUInteger iWrittenLength = writtenLength;
    // We need a count for pending writes because we do not know whether when the read stream hits an EOF
    // if it is enqueued before or after the last write block. 
    __block NSUInteger pendingWritesCount = 0;
    [self readDispatchDataWithLength:chunkLength
                               queue:queue
                             handler:^(BOOL readDone, dispatch_data_t _Nullable readDataChunk, NSError *_Nullable readError)
     {
         NSParameterAssert(queue.isCurrentDispatchQueue);
         
         NSUInteger readDataChunkSize = readDataChunk ? dispatch_data_get_size(readDataChunk) : 0;
         
         BOOL readReachedEOF = readDone && readDataChunkSize == 0;
         if(readError || readReachedEOF)
         {
             // If a write is still running its result block might not be enqueud yet. 
             // So in this case we leave it to the write block to call the completionHandler.
             if(completionHandler && pendingWritesCount == 0)
                 completionHandler(iWrittenLength, readError);
         }
         else if(readDataChunkSize > 0)
         {
             pendingWritesCount++;
             [targetStream writeDispatchData:readDataChunk
                                       queue:queue
                                     handler:^(BOOL writeDone, dispatch_data_t remainingWriteData, NSError *_Nullable writeError)
              {
                  NSParameterAssert(queue.isCurrentDispatchQueue);
                  
                  if(writeError)
                  {
                      if(completionHandler)
                          completionHandler(iWrittenLength, writeError);
                  }
                  else if(writeDone)
                  {
                      iWrittenLength += readDataChunkSize;
                      
                      if(progressHandler)
                          progressHandler(iWrittenLength);
                      
                      if(readReachedEOF || readError || (length != NSNotFound && iWrittenLength == length))
                      {
                          if(completionHandler)
                              completionHandler(iWrittenLength, readError);
                      }
                      else
                      {
                          // we decrement the pendingCount past the point where the completionHandler is called to
                          // prevent a following read-EOF from triggering the handler again.
                          pendingWritesCount--;  
                          [self doCopyDataWithLength:length
                                    inChunksOfLength:chunkLength
                                            toStream:targetStream
                                       writtenLength:iWrittenLength
                                               queue:queue
                                     progressHandler:progressHandler
                                   completionHandler:completionHandler];
                      }
                  }
              }];
         }
     }];
}

@end

NS_ASSUME_NONNULL_END
