//
//  NSTimer-PWExtensions.m
//  PWFoundation
//
//  Created by Andreas Känner on 09.03.09.
//
//

#import "NSTimer-PWExtensions.h"

@interface PWTimerTrampoline : NSObject
{
    __weak id   _target;
    SEL         _selector;
}

- (instancetype)initWithTarget:(id)target selector:(SEL)selector;

@end

@implementation PWTimerTrampoline

- (instancetype)initWithTarget:(id)target selector:(SEL)selector
{
    NSParameterAssert (target);
    NSParameterAssert (selector);
    
    if(self = [super init])
    {
        _target   = target;
        _selector = selector;
    }
    return self;
}

- (void)fire:(NSTimer *)timer
{
    id target = _target;    // weak -> strong
    if(target)
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:_selector withObject:self];
#pragma clang diagnostic pop
    }
    else
        [timer invalidate];
}

@end

@implementation NSTimer (PWFoundation)

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti weakTarget:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    PWTimerTrampoline* trampoline = [[PWTimerTrampoline alloc] initWithTarget:target selector:aSelector];
    return [NSTimer scheduledTimerWithTimeInterval:ti target:trampoline selector:@selector(fire:) userInfo:userInfo repeats:repeats];
}

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti weakTarget:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats
{
    PWTimerTrampoline* trampoline = [[PWTimerTrampoline alloc] initWithTarget:target selector:aSelector];
    return [NSTimer timerWithTimeInterval:ti target:trampoline selector:@selector(fire:) userInfo:userInfo repeats:repeats];
}
@end
