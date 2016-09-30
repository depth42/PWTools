//
//  Intercepted_objc_exception_throw.m
//  PWFoundation
//
//  Created by Kai Brüning on 25.5.12.
//
//

#import "Intercept_objc_exception_throw.h"
#import "mach_override.h"
#import "PWLog.h"

// IMPORTANT: this file must be compiled with ARC disabled.
// Somehow ARC messes up the retain count of the exception, resulting in the exception being overretained and leaked.

#ifndef NDEBUG

void intercepted_objc_exception_throw (NSException* exception);

typedef void (*objc_exception_throw_ptr) (NSException* exception);

// Accessor function for global in Intercept_objc_exception_throw.m
objc_exception_throw_ptr original_objc_exception_throw();

void intercepted_objc_exception_throw (NSException* exception)
{
    if (!isExceptionExpected(exception))
        PWLog (@"Throwing exception %@\n", exception);  // set exception catch breakpoint on this line

    original_objc_exception_throw() (exception);
}

#endif
