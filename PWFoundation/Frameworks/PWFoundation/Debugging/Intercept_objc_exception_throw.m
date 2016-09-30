//
//  Intercept_objc_exception_throw.m
//  PWFoundation
//
//  Created by Kai Brüning on 25.5.12.
//
//

#import "Intercept_objc_exception_throw.h"
#import "mach_override.h"
#import "PWLog.h"
#import "PWDispatch.h"

#ifndef NDEBUG

void objc_exception_throw (NSException* exception);

// The wrapper for objc_exception_throw is implemented in a separate file (Intercepted_objc_exception_throw.m) which
// is compiled without ARC. Somehow ARC messed up the retain count of the exception, resulting in the exception being
// overretained and leaked.
void intercepted_objc_exception_throw (NSException* exception);

typedef void (*objc_exception_throw_ptr) (NSException* exception);
objc_exception_throw_ptr g_objc_exception_throw;

static NSCountedSet* gExpectedExceptionFilters;

// Two accessor functions used by Intercepted_objc_exception_throw.m
objc_exception_throw_ptr original_objc_exception_throw()
{
    return g_objc_exception_throw;
}

#endif


PWDispatchQueue* expectedExceptionFiltersDispatchQueue()
{
    static PWDispatchQueue* queue;
    PWDispatchOnce(^{
        queue = [PWDispatchQueue serialDispatchQueueWithLabel:@"expectedExceptionFiltersDispatchQueue"];
    });
    return queue;
}

void registerExpectedExceptionFilter (PWExpectedExceptionFilter filter)
{
#ifndef NDEBUG
    NSCParameterAssert (filter);
    NSCParameterAssert( [filter copy] == (id)filter);   // To make unregistering work, the block needs to be already copied so that we remain pointer identity

    [expectedExceptionFiltersDispatchQueue() asynchronouslyDispatchBlock:^{
         if (!gExpectedExceptionFilters)
             gExpectedExceptionFilters = [[NSCountedSet alloc] init];
        [gExpectedExceptionFilters addObject:filter];
     }];

#endif
}

BOOL unregisterExpectedExceptionFilter (PWExpectedExceptionFilter filter)
{
    __block BOOL success = YES;
#ifndef NDEBUG
    NSCParameterAssert (filter);
    [expectedExceptionFiltersDispatchQueue() synchronouslyDispatchBlock:^{
        success = [gExpectedExceptionFilters containsObject:filter];
        [gExpectedExceptionFilters removeObject:filter];
    }];
#endif
    return success;
}

#ifndef NDEBUG
BOOL isExceptionExpected (NSException* exception)
{
    NSCParameterAssert (exception);

    __block BOOL result = NO;
    [expectedExceptionFiltersDispatchQueue() synchronouslyDispatchBlock:^{
        for (PWExpectedExceptionFilter iFilter in gExpectedExceptionFilters)
        {
            if(iFilter(exception))
            {
                result = YES;
                break;
            }
        }
    }];
    return result;
}
#endif

void intercept_objc_exception_throw()
{
#ifndef NDEBUG
// Cannot override mach functions in iOS devices, but it works just fine in the simulator.
#if UXTARGET_OSX || TARGET_IPHONE_SIMULATOR
    // Patch once only.
    if (!g_objc_exception_throw) {
        mach_error_t err = mach_override_ptr (objc_exception_throw,
                                              intercepted_objc_exception_throw,
                                              (void**)&g_objc_exception_throw);	
        if (err) {
            PWLog (@"Could not patch objc_exception_throw(). ");
            if (err == err_cannot_override)
                PWLog (@"Make sure you do not have an active Objective-C Exception Breakpoint.\n");
            else
                PWLog (@"Mach error = %i.\n", err);
        }
    }
#endif
#endif
}
