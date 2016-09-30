//
//  Intercept_objc_exception_throw.h
//  PWFoundation
//
//  Created by Kai Brüning on 25.5.12.
//
//


#ifdef	__cplusplus
extern	"C"	{
#endif

// Return value of YES means that 'exception' is expected in normal operation and the exception breakpoint should not
// be triggered.
typedef BOOL (^PWExpectedExceptionFilter) (NSException* exception);
    
// Patches objc_exception_throw(), unless NDEBUG is defined.
void intercept_objc_exception_throw();

void registerExpectedExceptionFilter (PWExpectedExceptionFilter filter);

// Unregistering will work only if the block has been copied before passing it to registerExpectedExceptionFilter()
// and that same pointer is passed to unregisterExpectedExceptionFilter().
// Returns whether 'filter' was found and unregistered.
BOOL unregisterExpectedExceptionFilter (PWExpectedExceptionFilter filter);

#ifndef NDEBUG
BOOL isExceptionExpected (NSException* exception);
#endif

#ifdef	__cplusplus
}
#endif
