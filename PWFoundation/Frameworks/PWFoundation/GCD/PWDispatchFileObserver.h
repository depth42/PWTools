//
//  PWDispatchFileObserver.h
//  PWFoundation
//
//  Created by Frank Illenberger on 21.07.09.
//
//

#import <PWFoundation/PWDispatchSource.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, PWDispatchFileEventMask) {
    PWDispatchFileDelete        = DISPATCH_VNODE_DELETE,
    PWDispatchFileWrite         = DISPATCH_VNODE_WRITE,
    PWDispatchFileExtend        = DISPATCH_VNODE_EXTEND,
    PWDispatchFileAttributes    = DISPATCH_VNODE_ATTRIB,
    PWDispatchFileLink          = DISPATCH_VNODE_LINK,
    PWDispatchFileRename        = DISPATCH_VNODE_RENAME,
    PWDispatchFileRevoke        = DISPATCH_VNODE_REVOKE,
};

@interface PWDispatchFileObserver : PWDispatchSource 

- (instancetype)initWithFileURL:(NSURL*)aURL
            eventMask:(PWDispatchFileEventMask)mask 
              onQueue:(id<PWDispatchQueueing>)queue;

// Retains fileHandle until the source is cancelled.
- (instancetype)initWithFileHandle:(NSFileHandle*)fileHandle
               eventMask:(PWDispatchFileEventMask)mask
                 onQueue:(id<PWDispatchQueueing>)queue;

@property (nonatomic, readonly)                     PWDispatchFileEventMask    eventMask;
@property (nonatomic, readonly, copy, nullable)     NSURL*                     URL;         // nil for -initWithFileHandle:...
@property (nonatomic, readonly, strong, nullable)   NSFileHandle*              fileHandle;  // nil for -initWithFileURL:...

@end

NS_ASSUME_NONNULL_END
