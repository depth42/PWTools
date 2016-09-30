//
//  PWTemporaryExceptionFilter.m
//  PWFoundation
//
//  Created by Kai Brüning on 15.8.12.
//
//

#import "PWTemporaryExceptionFilter.h"
#import "PWDispatch.h"

@implementation PWTemporaryExceptionFilter

+ (PWTemporaryExceptionFilter*) exceptionFilterWithFilterBlock:(PWExpectedExceptionFilter)filterBlock
{
#ifndef NDEBUG
    return [[PWTemporaryExceptionFilter alloc] initWithFilterBlock:filterBlock];
#else
    return nil;
#endif
}

#ifndef NDEBUG
- (instancetype) initWithFilterBlock:(PWExpectedExceptionFilter)filterBlock
{
    NSParameterAssert (filterBlock);
    
    if ((self = [super init]) != nil) {
        _filterBlock = [filterBlock copy];
        registerExpectedExceptionFilter (_filterBlock);
    }
    return self;
}
#endif

- (void) dispose
{
#ifndef NDEBUG
    if (_filterBlock) {
        BOOL success = unregisterExpectedExceptionFilter (_filterBlock);
        NSAssert (success, nil);
        _filterBlock = nil;
    }
#endif
}

#ifndef NDEBUG
- (void) dealloc
{
    [self dispose];
}
#endif

@end
