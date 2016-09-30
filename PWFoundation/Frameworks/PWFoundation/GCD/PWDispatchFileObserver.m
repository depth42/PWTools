//
//  PWDispatchFileObserver.m
//  PWFoundation
//
//  Created by Frank Illenberger on 21.07.09.
//
//

#import "PWDispatchFileObserver.h"
#import "PWDispatchSource-Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchFileObserver

@synthesize eventMask  = eventMask_;
@synthesize URL        = URL_;
@synthesize fileHandle = fileHandle_;

- (instancetype)initWithFileDescriptor:(int)fileDescriptor
                   eventMask:(PWDispatchFileEventMask)mask
                     onQueue:(id<PWDispatchQueueing>)queue
{
    NSParameterAssert (fileDescriptor != -1);

    return [self initWithFileHandle:[[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor
                                                                  closeOnDealloc:NO]
                          eventMask:mask
                            onQueue:queue];
}

- (instancetype)initWithFileURL:(NSURL*)aURL
            eventMask:(PWDispatchFileEventMask)mask
              onQueue:(id<PWDispatchQueueing>)queue
{
    NSParameterAssert(aURL.isFileURL);
    // We have to handle the file descriptor directly because NSFileHandle does not like O_EVTONLY
    int fileDescriptor = open(aURL.path.UTF8String, O_EVTONLY);
    if (fileDescriptor == -1)
        return nil;
    else
        return [self initWithFileHandle:[[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor
                                                                      closeOnDealloc:YES]
                              eventMask:mask
                                onQueue:queue];
}

- (instancetype)initWithFileHandle:(NSFileHandle*)fileHandle
               eventMask:(PWDispatchFileEventMask)mask
                 onQueue:(id<PWDispatchQueueing>)queue
{
    NSParameterAssert (fileHandle);

    if ((self = [self initWithType:DISPATCH_SOURCE_TYPE_VNODE
                            handle:fileHandle.fileDescriptor
                              mask:mask
                           onQueue:queue]) != nil) {
        fileHandle_ = fileHandle;
        self.cancelBlock = nil;
    }
    return self;
}

// Overwritten from PWDispatchSource.
- (void) cancel
{
    fileHandle_ = nil;  // note: kept alive by cancellation block until the block is called.

    [super cancel];
}

- (void) setCancelBlock:(nullable PWDispatchBlock)handler
{
    NSFileHandle* fileHandle = fileHandle_;
    // From Apples documentation:
    // The optional cancellation handler is submitted to the dispatch source object's target queue only after
    // the system has released all of its references to any underlying system objects (file descriptors or mach
    // ports). Thus, the cancellation handler is a convenient place to close or deallocate such system objects.
    // Note that it is invalid to close a file descriptor or deallocate a mach port currently being tracked by
    // a dispatch source object before the cancellation handler is invoked.
    // Therefore I capture the file handle in the cancellation block to ensure it is not released before this block
    // is called.
    [super setCancelBlock:^{
        (void)fileHandle.fileDescriptor;
        if(handler)
            handler();
    }];
}

@end

NS_ASSUME_NONNULL_END
