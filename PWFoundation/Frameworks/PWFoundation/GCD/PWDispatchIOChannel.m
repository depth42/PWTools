//
//  PWDispatchIOChannel.m
//  PWFoundation
//
//  Created by Frank Illenberger on 15.03.12.
//
//

#import "PWDispatchIOChannel.h"
#import "PWDispatchQueue.h"
#import "PWDispatchObject-Internal.h"
#import "PWErrors.h"
#import "NSData-PWDispatchExtensions.h"
#import "NSArray-PWExtensions.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^PWDispatchIONativeCleanupHandler)(int errorCode);

@implementation PWDispatchIOChannel
{
    PWDispatchQueue*                    _handleDispatchQueue;        // Protects the _fileHandle ivar for channels created via via
                                                                     // -initWithType:URL:openFlags:creationMode:queue:cleaupHandler
    BOOL                                _hasCleanedUp;
#ifndef NDEBUG
    NSDate*                             _lastReadThrottleDate;
    NSDate*                             _lastWriteThrottleDate;
    PWDispatchQueue*                    _throttleWriteDispatchQueue;
    NSMutableArray<PWDispatchBlock>*    _throttleWriteQueue;
    BOOL                                _isThrottleWriting;
#endif
}

- (dispatch_io_type_t)dispatchIOType
{
    NSAssert(NO, @"abstract");
    return 0;
}

- (instancetype) initWithHandle:(NSFileHandle*)fileHandle
                queue:(id<PWDispatchQueueing>)cleanupQueue
       cleanupHandler:(nullable PWDispatchIOCleanupHandler)cleanupHandler
{
    NSParameterAssert(fileHandle);
    NSParameterAssert(cleanupQueue);

    dispatch_io_t newChannel = dispatch_io_create(self.dispatchIOType,
                                                  fileHandle.fileDescriptor, 
                                                  cleanupQueue.dispatchQueueForNativeAPIs.underlyingQueue,
                                                  ^(int errorCode) {
                                                      PWDispatchCallBlockFromNativeAPI (cleanupQueue, ^{
                                                          [self cleanupWithHandler:cleanupHandler errorCode:errorCode];
                                                      });
                                                  });
    if (!newChannel)
        return nil;
#ifndef NDEBUG
    _throttleWriteDispatchQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWDispatchIOChannel_throttle"];
    _throttleWriteQueue = [[NSMutableArray alloc] init];
#endif
    if ((self = [super initWithUnderlyingObject:newChannel]) != nil)
    {
        _fileHandle = fileHandle;
    }
    return self;
}

- (instancetype) initWithURL:(NSURL*)fileURL
         openFlags:(int)openFlags
      creationMode:(mode_t)creationMode
             queue:(id<PWDispatchQueueing>)cleanupQueue
    cleanupHandler:(nullable PWDispatchIOCleanupHandler)cleanupHandler
{
    NSParameterAssert(fileURL.isFileURL);
    NSParameterAssert(cleanupQueue);

    dispatch_io_t newChannel = dispatch_io_create_with_path(self.dispatchIOType,
                                                            fileURL.path.fileSystemRepresentation,
                                                            openFlags,
                                                            creationMode,
                                                            cleanupQueue.dispatchQueueForNativeAPIs.underlyingQueue,
                                                            ^(int errorCode) {
                                                                PWDispatchCallBlockFromNativeAPI (cleanupQueue, ^{
                                                                    [self cleanupWithHandler:cleanupHandler errorCode:errorCode];
                                                                });
                                                            });
    if (!newChannel)
        return nil;
    
    if ((self = [super initWithUnderlyingObject:newChannel]) != nil)
    {
        // The file handle is created later on demand. For sychronizing the creation we need a dispatch queue. 
        _handleDispatchQueue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromClass(self.class)];
    }
    return self;
}

- (instancetype) initWithIOChannel:(PWDispatchIOChannel*)channel
                   queue:(id<PWDispatchQueueing>)cleanupQueue
          cleanupHandler:(nullable PWDispatchIOCleanupHandler)cleanupHandler
{
    NSParameterAssert(channel);
    NSParameterAssert(cleanupQueue);

    dispatch_io_t newChannel = dispatch_io_create_with_io(self.dispatchIOType,
                                                          (dispatch_io_t)channel.underlyingObject,
                                                          cleanupQueue.dispatchQueueForNativeAPIs.underlyingQueue,
                                                          ^(int errorCode) {
                                                              PWDispatchCallBlockFromNativeAPI (cleanupQueue, ^{
                                                                  [self cleanupWithHandler:cleanupHandler errorCode:errorCode];
                                                              });
                                                          });
    
    if (!newChannel)
        return nil;
    
    if ((self = [super initWithUnderlyingObject:newChannel]) != nil)
    {
        _fileHandle = channel->_fileHandle;
        // The file handle is created later on demand. For sychronizing the creation we need a dispatch queue. 
        if(!_fileHandle)
            _handleDispatchQueue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromClass(self.class)];
    }
    return self;
}

- (void) cleanupWithHandler:(nullable PWDispatchIOCleanupHandler)cleanupHandler errorCode:(int)errorCode
{
    [self willChangeValueForKey:@"isOpen"];
    _hasCleanedUp = YES;
    [self didChangeValueForKey:@"isOpen"];
    if (cleanupHandler)
        cleanupHandler (self, [self errorFromErrorCode:errorCode]);
    // We need to keep our reference to the fileHandle up to this point to keep the underlying
    // file descriptor alive as along as the channel needs it.
    _fileHandle = nil;
}

@synthesize fileHandle = _fileHandle;

- (nullable NSFileHandle*)fileHandle
{
    // If there is no _handleDispatchQueue, the fileHandle has been invariantly created at init time
    // and we can simply return it.
    if(!_handleDispatchQueue)
        return _fileHandle;

    // Channels created via -initWithType:URL:openFlags:creationMode:queue:cleanupHandler
    // get their file handle instance created on demand.
    __block NSFileHandle* fileHandle;
    [_handleDispatchQueue synchronouslyDispatchBlock:^{
        if(!_fileHandle)
        {
            int fd = dispatch_io_get_descriptor((dispatch_io_t)impl_);
            if(fd != -1)
                _fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fd closeOnDealloc:NO];
        }
        fileHandle = _fileHandle;
    }];
    return fileHandle;
}

- (BOOL)isOpen
{
    // A cleaned-up channel always stays closed
    if(_hasCleanedUp)
        return NO;
    
    // If the channel is not disposed we need to use the on-demand getter to get the file handle
    // to actually determine is the channel is open or closed.
    return (self.fileHandle != nil);
}

- (void)setInterval:(NSTimeInterval)value strict:(BOOL)strict
{
    dispatch_io_set_interval((dispatch_io_t)impl_, 
                             value * 1E9,   // in nanoseconds
                             strict ? DISPATCH_IO_STRICT_INTERVAL : 0);
}

- (void)setLowWater:(NSInteger)value
{
    dispatch_io_set_low_water((dispatch_io_t)impl_, value);
}

- (void)setHighWater:(NSInteger)value
{
    dispatch_io_set_high_water((dispatch_io_t)impl_, value);
}

#ifndef NDEBUG

- (void)setThrottleRate:(NSUInteger)throttleRate
{
    _throttleRate = throttleRate;
    if(throttleRate > 0)
        self.highWater = throttleRate / 4;
}

- (void)throttleAfterPacketWithSize:(NSInteger)packetSize isWrite:(BOOL)isWrite
{
    if(_throttleRate > 0 && packetSize > 0)
    {
        NSDate* date = isWrite ? _lastWriteThrottleDate : _lastReadThrottleDate;
        if(date)
        {
            NSTimeInterval requiredInterval = (double)packetSize / (double)_throttleRate;
            NSTimeInterval actualInterval = -date.timeIntervalSinceNow;
            if(actualInterval < requiredInterval)
                [NSThread sleepForTimeInterval:requiredInterval-actualInterval];
        }
        if(isWrite)
            _lastWriteThrottleDate = [NSDate date];
        else
            _lastReadThrottleDate = [NSDate date];
    }
}

#endif

- (void)closeImmediately:(BOOL)immediately // If immediately==NO, all pending actions are completed
{
    dispatch_io_close((dispatch_io_t)impl_, immediately ? DISPATCH_IO_STOP : 0);
    // Note: The _fileHandle is nilled out when the cleanup handler of the channel is called
}

- (void)dispatchBarrierBlock:(PWDispatchBlock)block
{
    NSParameterAssert(block);
    dispatch_io_barrier((dispatch_io_t)impl_, block);
}

- (nullable NSError*)errorFromErrorCode:(int)code
{
    if(code == 0)
        return nil;
    else 
    {
        NSString* message = [NSString stringWithFormat:@"Received an error from PWDispatchIOChannel: %d (%s)", code, strerror(code)];
        NSMutableDictionary* info = [NSMutableDictionary dictionary];
        info[PWDispatchIOChannelErrorUnderlyingCodeKey] = @(code);
        info[NSLocalizedDescriptionKey] = message;
        return [NSError errorWithDomain:PWErrorDomain code:PWDispatchIOChannelError userInfo:info];
    }
}

- (void)readDispatchDataStartingFromOffset:(NSUInteger)offset
                                    length:(NSUInteger)length
                                     queue:(id<PWDispatchQueueing>)queue
                                   handler:(void (^)(BOOL done, dispatch_data_t _Nullable data, NSError* _Nullable errorOrNil))handler
{
    NSParameterAssert(handler);
    NSParameterAssert(queue);

    dispatch_io_read((dispatch_io_t)impl_,
                     offset,
                     (length == NSNotFound ? SIZE_MAX : length),
                     queue.dispatchQueueForNativeAPIs.underlyingQueue,
                     ^(bool done, dispatch_data_t data, int errorCode) {
                         PWDispatchCallBlockFromNativeAPI (queue, ^{
#ifndef NDEBUG
                             if(!done)
                                 [self throttleAfterPacketWithSize: data ? dispatch_data_get_size(data) : 0 isWrite:NO];
#endif
                             handler (done, data, [self errorFromErrorCode:errorCode]);
                         });
                     });
}

- (void) writeDispatchData:(dispatch_data_t)data
        startingFromOffset:(NSUInteger)offset
                     queue:(nullable id<PWDispatchQueueing>)queue
                   handler:(nullable void (^)(BOOL done, dispatch_data_t _Nullable remainingData, NSError* _Nullable errorOrNil))handler
{
    NSParameterAssert(data);
    NSParameterAssert(queue);
    NSParameterAssert(handler);

#ifndef NDEBUG
    if(_throttleRate > 0.0)
        [self throttledWriteData:(NSData*)data startingFromOffset:offset queue:queue handler:^(BOOL done, NSUInteger remainingLength, NSError * _Nullable errorOrNil) {
            dispatch_data_t remainingData = dispatch_data_create_subrange(data, dispatch_data_get_size(data) - remainingLength, remainingLength);
            handler(done, remainingData, errorOrNil);
        }];
    else
#endif
    dispatch_io_write((dispatch_io_t)impl_,
                      offset,
                      data,
                      queue.dispatchQueueForNativeAPIs.underlyingQueue,
                      ^(bool done, dispatch_data_t remainingData, int errorCode) {
                          PWDispatchCallBlockFromNativeAPI (queue, ^{
                              handler (done, data, [self errorFromErrorCode:errorCode]);
                          });
                      });
}

- (void)readDataStartingFromOffset:(NSUInteger)offset
                            length:(NSUInteger)length
                             queue:(id<PWDispatchQueueing>)queue
                           handler:(void (^)(BOOL done, NSData* _Nullable data, NSError* _Nullable errorOrNil))handler
{
    NSParameterAssert(handler);
    NSParameterAssert(queue);

    dispatch_io_read((dispatch_io_t)impl_,
                     offset, 
                     (length == NSNotFound ? SIZE_MAX : length),
                     queue.dispatchQueueForNativeAPIs.underlyingQueue,
                     ^(bool done, dispatch_data_t dispatchData, int errorCode) {
                         NSData* data = dispatchData ? [NSData dataWithDispatchData:dispatchData] : nil;
                         PWDispatchCallBlockFromNativeAPI (queue, ^{
#ifndef NDEBUG
                             [self throttleAfterPacketWithSize:data.length isWrite:NO];
#endif
                             handler (done, data, [self errorFromErrorCode:errorCode]);
                         });
                     });
}

- (void) writeData:(NSData*)data
startingFromOffset:(NSUInteger)offset
             queue:(id<PWDispatchQueueing>)queue
           handler:(void (^)(BOOL done, NSUInteger remainingLength, NSError* _Nullable errorOrNil))handler
{
    NSParameterAssert(data);
    NSParameterAssert(queue);
    NSParameterAssert(handler);

#ifndef NDEBUG
    if(_throttleRate > 0.0)
        [self throttledWriteData:data startingFromOffset:offset queue:queue handler:handler];
    else
#endif
        [self doWriteData:data startingFromOffset:offset queue:queue handler:handler];
}

- (void) doWriteData:(NSData*)data
  startingFromOffset:(NSUInteger)offset
               queue:(id<PWDispatchQueueing>)queue
             handler:(void (^)(BOOL done, NSUInteger remainingLength, NSError* _Nullable errorOrNil))handler
{
    NSParameterAssert(data);
    NSParameterAssert(queue);
    NSParameterAssert(handler);

    dispatch_data_t dispatchData = [data newDispatchData];
    dispatch_io_write((dispatch_io_t)impl_,
                      offset,
                      dispatchData,
                      queue.dispatchQueueForNativeAPIs.underlyingQueue,
                      ^(bool done, dispatch_data_t remainingData, int errorCode) {
                          NSInteger remainingLength = remainingData ? dispatch_data_get_size(remainingData) : 0;
                          PWDispatchCallBlockFromNativeAPI (queue, ^{
                              handler(done, remainingLength, [self errorFromErrorCode:errorCode]);
                          });
                      });
}

#ifndef NDEBUG

- (void) throttledWriteData:(NSData*)data
         startingFromOffset:(NSUInteger)offset
                      queue:(id<PWDispatchQueueing>)queue
                    handler:(void (^)(BOOL done, NSUInteger remainingLength, NSError* _Nullable errorOrNil))handler
{
    NSParameterAssert(data);
    NSParameterAssert(queue);
    NSParameterAssert(handler);
    NSParameterAssert(offset == 0);     // Other offsets are currently not supported for throttling

    PWDispatchBlock block = ^{
        PWAssert(_throttleWriteDispatchQueue.isCurrentDispatchQueue);
        PWAssert(!_isThrottleWriting);
        _isThrottleWriting = YES;

       __block NSUInteger totalWrittenLength = 0;
        NSArray<NSData*>* subdatas = [self.class subdatasFromData:data
                                                    withBlockSize:_throttleRate / 4
                                                       fromOffset:offset];

        [subdatas asynchronouslyEnumerateObjectsUsingBlock:^(NSData* subData, PWAsynchronousEnumerationObjectCompletionHandler objectCompletionHandler) {
            __block NSUInteger blockWrittenLength = 0;
            __block NSUInteger blockStartTotalWrittenLength = totalWrittenLength;

            [self doWriteData:subData startingFromOffset:offset queue:_throttleWriteDispatchQueue handler:^(BOOL done, NSUInteger remainingLength, NSError * _Nullable errorOrNil) {
                blockWrittenLength = subData.length - remainingLength;
                totalWrittenLength = blockStartTotalWrittenLength + blockWrittenLength;
                [queue asynchronouslyDispatchBlock:^{
                    handler(done && subData == subdatas.lastObject, data.length - totalWrittenLength, errorOrNil);
                }];

                if(done)
                    [self throttleAfterPacketWithSize:subData.length isWrite:YES];

                if(errorOrNil)
                {
                    objectCompletionHandler(/* stop */ YES, errorOrNil);
                    return;
                }

                if(done)
                {
                    objectCompletionHandler(/* stop */ NO, errorOrNil);
                }
            }];
        } completionHandler:^(BOOL didFinish, NSError* _Nullable lastError) {
            _isThrottleWriting = NO;
            [self performNextThrottleWrite];
        }];
    };

    [_throttleWriteDispatchQueue asynchronouslyDispatchBlock:^{
        [_throttleWriteQueue addObject:[block copy]];
        if(!_isThrottleWriting)
            [self performNextThrottleWrite];
    }];
}

- (void)performNextThrottleWrite
{
    PWAssert(_throttleWriteDispatchQueue.isCurrentDispatchQueue);
    PWAssert(!_isThrottleWriting);

    if(_throttleWriteQueue.count > 0)
    {
        PWDispatchBlock block = _throttleWriteQueue[0];
        [_throttleWriteQueue removeObjectAtIndex:0];
        block();
    }
}

#endif

+ (NSArray<NSData*>*)subdatasFromData:(NSData*)data
                        withBlockSize:(NSUInteger)blockSize
                           fromOffset:(NSUInteger)offset
{
    NSParameterAssert(blockSize > 0);

    NSMutableArray<NSData*>* subdatas = [NSMutableArray array];
    NSUInteger length = data.length;
    while(offset < length)
    {
        NSData* subdata = [data subdataWithRange:NSMakeRange(offset, MIN(blockSize, length - offset))];
        [subdatas addObject:subdata];
        offset += subdata.length;
    }
    return subdatas;
}
@end

NS_ASSUME_NONNULL_END
