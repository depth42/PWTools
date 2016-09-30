//
//  PWKeyedBlockQueue.m
//  PWFoundation
//
//  Created by Frank Illenberger on 16.11.12.
//
//

#import "PWKeyedBlockQueue.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWKeyedBlockQueue
{
    NSMutableArray*         _keysArray;
    NSMutableDictionary*    _blockByKey;
    NSUInteger              _suspendCount;
    BOOL                    _isDisposed;
}

- (void)suspend
{
    NSAssert(_suspendCount < 10, nil);
    _suspendCount ++;
}

- (void)resume
{
    NSAssert(_suspendCount > 0, nil);
    _suspendCount--;
    if(_suspendCount == 0)
        [self performAllPendingBlocks];
}

- (BOOL)isSuspended
{
    return _suspendCount > 0;
}

- (void)forKey:(NSString*)key performBlock:(PWDispatchBlock)block
{
    NSParameterAssert(key);
    NSParameterAssert(block);

    NSAssert(!_isDisposed, nil);
    if(_isDisposed) // paranoia
        return;

    if(self.isSuspended)
    {
        if(!_keysArray)
        {
            NSAssert(!_blockByKey, nil);
            _keysArray  = [[NSMutableArray alloc] init];
            _blockByKey = [[NSMutableDictionary alloc] init];
        }

        if(!_blockByKey[key])
        {
            key = [key copy];
            _blockByKey[key] = [block copy];
            [_keysArray addObject:key];
        }
    }
    else
        block();
}

- (void)performAllPendingBlocks
{
    NSArray* keys = _keysArray;
    NSDictionary* blockByKey = _blockByKey;

    _keysArray  = nil;
    _blockByKey = nil;

    NSNull* null = NSNull.null;

    for(id iKey in keys)
    {
        if(iKey != null)
        {
            PWDispatchBlock block = blockByKey[iKey];
            NSAssert(block, nil);
            block();
        }
    }
}

- (void)performPendingBlockForKey:(NSString*)key
{
    NSParameterAssert(key);

    PWDispatchBlock block = _blockByKey[key];
    if(block)
    {
        [_blockByKey removeObjectForKey:key];
        if(_blockByKey.count == 0)
        {
            _keysArray = nil;
            _blockByKey = nil;
        }
        else
        {
            // Note: We linarly look for the key which leads to O(n^2) behavior for picked blocks.
            // But as we expect the total number of blocks to be small (<10) we are fine with this
            NSUInteger index = [_keysArray indexOfObject:key];
            NSAssert(index != NSNotFound, nil);
            _keysArray[index] = NSNull.null;   // remove key by nulling out to avoid further O(n^2) behavior
        }
        block();
    }
}

- (void)dispose
{
    // break retain cycles
    _blockByKey = nil;
    _keysArray = nil;   // keep invariant intact
    _isDisposed = YES;
}
@end


NS_ASSUME_NONNULL_END
