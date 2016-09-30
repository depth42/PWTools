//
//  PWDelayedPerformer.m
//  PWFoundation
//
//  Created by Kai Brüning on 22.11.11.
//
//

#import "PWDelayedPerformer.h"

typedef enum
{
    PWDelayedPerformerTypeDelay,
    PWDelayedPerformerTypeOrder,
} PWDelayedPerformerType;

@implementation PWDelayedPerformer
{
    PWDispatchBlock         _block;
    PWDelayedPerformerType  _type;
}

- (instancetype) initUsingBlock:(PWDispatchBlock)block
                           type:(PWDelayedPerformerType)type
{
    if(self = [super init])
    {
        _type = type;
        _block = [block copy];
    }
    return self;
}


- (instancetype) initUsingBlock:(PWDispatchBlock)block
                     afterDelay:(NSTimeInterval)delay
                        inModes:(NSArray*)modes
{
    NSParameterAssert (block);
    
    if (self = [self initUsingBlock:block type:PWDelayedPerformerTypeDelay])
    {
        [self performSelector:@selector(perform)
                   withObject:nil
                   afterDelay:delay
                      inModes:modes];
    }
    return self;
}

- (instancetype) initUsingBlock:(PWDispatchBlock)block
                          order:(NSUInteger)order
                        inModes:(NSArray*)modes
{
    NSParameterAssert (block);

    if (self = [self initUsingBlock:block type:PWDelayedPerformerTypeOrder])
    {
        [NSRunLoop.currentRunLoop performSelector:@selector(perform)
                                           target:self
                                         argument:nil
                                            order:order
                                            modes:modes];
    }
    return self;
}

- (void) performNow
{
    if (_block) {
        [self perform];
        [self dispose];
    }
}

- (void) perform
{
    NSAssert (_block, @"unexpected delayed perform after cancelling");
    PWDispatchBlock block = _block;     // make sure the block stays alive while calling it
    _block = nil;
    block();
    // Important: must no longer access ivars at this point, this object may be disposed now.
}

- (void) dispose
{
    if (_block) {
        switch (_type)
        {
            case PWDelayedPerformerTypeDelay:
                [NSObject cancelPreviousPerformRequestsWithTarget:self];
                break;
                
            case PWDelayedPerformerTypeOrder:
                [NSRunLoop.currentRunLoop cancelPerformSelector:@selector(perform)
                                                         target:self
                                                       argument:nil];
                break;
        }
        _block = nil;
    }
}

@end

#pragma mark -

@implementation NSObject (PWDelayedPerformer)

+ (PWDelayedPerformer*) performerWithDelay:(NSTimeInterval)delay inModes:(NSArray*)modes usingBlock:(PWDispatchBlock)block
{
    return [[PWDelayedPerformer alloc] initUsingBlock:block afterDelay:delay inModes:modes];
}

+ (PWDelayedPerformer*) performerWithDelay:(NSTimeInterval)delay usingBlock:(PWDispatchBlock)block
{
    return [self performerWithDelay:delay
                            inModes:@[NSRunLoopCommonModes]
                         usingBlock:block];
}

+ (PWDelayedPerformer*) performerWithOrder:(NSUInteger)order inModes:(NSArray*)modes usingBlock:(PWDispatchBlock)block
{
    return [[PWDelayedPerformer alloc] initUsingBlock:block order:order inModes:modes];
}

+ (PWDelayedPerformer*) performerWithOrder:(NSUInteger)order usingBlock:(PWDispatchBlock)block
{
    return [self performerWithOrder:order
                            inModes:@[NSRunLoopCommonModes]
                         usingBlock:block];
}

@end
