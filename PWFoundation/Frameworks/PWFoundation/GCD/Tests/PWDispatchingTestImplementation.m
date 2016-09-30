//
//  PWDispatchingTestImplementation.m
//  PWFoundation
//
//  Created by Kai Brüning on 1/09/15.
//
//

#import "PWDispatchingTestImplementation.h"

@implementation PWDispatchingTestImplementation
{
    PWDispatchQueue*    _queue;
    PWDispatchQueue*    _fallbackQueue;
}

- (instancetype) init
{
    if ((self = [super init]) != nil) {
        _queue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWDispatchingTestImplementation Underlying Queue"];
        _fallbackQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWDispatchingTestImplementation Fallback Queue"];
    }
    return self;
}

- (void) asynchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block
{
    [_queue asynchronouslyDispatchBlock:block];
}

- (void) asynchronouslyDispatchAfterDelay:(NSTimeInterval)delay
                              useWallTime:(BOOL)useWallTime
                                    block:(__unsafe_unretained PWDispatchBlock)block
{
    [_queue asynchronouslyDispatchAfterDelay:delay useWallTime:useWallTime block:block];
}

- (void) asynchronouslyDispatchAfterDate:(NSDate*)date block:(__unsafe_unretained PWDispatchBlock)block
{
    [_queue asynchronouslyDispatchAfterDate:date block:block];
}

- (void) synchronouslyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block
{
    [_queue synchronouslyDispatchBlock:block];
}

- (void) dynamicallyDispatchBlock:(__unsafe_unretained PWDispatchBlock)block
{
    [_queue dynamicallyDispatchBlock:block];
}

- (void) withDispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
            dispatchBlock:(__unsafe_unretained PWDispatchBlock)block
{
    switch (dispatchKind) {
        case PWDispatchQueueDispatchKindSynchronous:
            [self synchronouslyDispatchBlock:block];
            break;
        case PWDispatchQueueDispatchKindAsynchronous:
            [self asynchronouslyDispatchBlock:block];
            break;
        case PWDispatchQueueDispatchKindDynamic:
            [self dynamicallyDispatchBlock:block];
            break;
    }
}

- (void) asCurrentQueuePerformBlock:(PWDispatchBlock)block
{
    [_queue asCurrentQueuePerformBlock:block];
}

- (BOOL) isCurrentDispatchQueue
{
    return _queue.isCurrentDispatchQueue;
}

- (PWDispatchQueue*) dispatchQueueForNativeAPIs
{
    return _fallbackQueue;
}

- (NSString*) dispatchQueueLabel
{
    return @"PWDispatchingTestImplementation";
}

@end
