//
//  PWDispatchFileReader.m
//  PWFoundation
//
//  Created by Frank Illenberger on 20.07.09.
//
//

#import "PWDispatchFileReader.h"
#import "PWDispatchSource-Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchFileReader

- (instancetype) initWithFileHandle:(NSFileHandle*)handle
                  onQueue:(id<PWDispatchQueueing>)queue
{
    NSParameterAssert (handle);

    if(self = [self initWithType:DISPATCH_SOURCE_TYPE_READ
                          handle:handle.fileDescriptor
                            mask:0
                         onQueue:queue])
    {
        _fileHandle = handle;
        self.cancelBlock = nil;
    }
    return self;
}

- (NSUInteger)availableBytes
{
    return self.data;
}

- (void) setCancelBlock:(nullable PWDispatchBlock)handler
{
    NSFileHandle* fileHandle = _fileHandle;
    // From Apples documentation:
    // The optional cancellation handler is submitted to the dispatch source object's target queue only after
    // the system has released all of its references to any underlying system objects (file descriptors or mach
    // ports). Thus, the cancellation handler is a convenient place to close or deallocate such system objects.
    // Note that it is invalid to close a file descriptor or deallocate a mach port currently being tracked by
    // a dispatch source object before the cancellation handler is invoked.
    // Therefore I capture the file handle in the cancellation block to ensure it is not released before this block
    // is called.
    [super setCancelBlock:^{
        (void)fileHandle.hash;
        if(handler)
            handler();
    }];
}
@end

NS_ASSUME_NONNULL_END
