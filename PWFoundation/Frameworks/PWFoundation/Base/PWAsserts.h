//
//  PWAsserts.h
//  PWFoundation
//
//  Created by Frank Illenberger on 22.08.2012.
//
//

/*
 These macros are copied from NSException.h and are renamed and modified not to be removed from release builds
 (Checks of NS_BLOCK_ASSERTIONS have been removed).
*/

#if (defined(__STDC_VERSION__) && (199901L <= __STDC_VERSION__)) || (defined(__cplusplus) && (201103L <= __cplusplus))

#if !defined(_PWReleaseAssertBody)
#define PWReleaseAssert(condition, desc, ...)	\
do {				\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
if (!(condition)) {		\
[[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd \
object:self file:[NSString stringWithUTF8String:__FILE__] \
lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
}				\
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
} while(0)
#endif

#if !defined(_PWCReleaseAssertBody)
#define PWCReleaseAssert(condition, desc, ...) \
do {				\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
if (!(condition)) {		\
[[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] \
file:[NSString stringWithUTF8String:__FILE__] \
lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
}				\
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
} while(0)
#endif

#if !defined(_PWReleaseAssertBody)
#define PWReleaseAssert1(condition, desc, arg1) PWReleaseAssert((condition), (desc), (arg1))
#define PWReleaseAssert2(condition, desc, arg1, arg2) PWReleaseAssert((condition), (desc), (arg1), (arg2))
#define PWReleaseAssert3(condition, desc, arg1, arg2, arg3) PWReleaseAssert((condition), (desc), (arg1), (arg2), (arg3))
#define PWReleaseAssert4(condition, desc, arg1, arg2, arg3, arg4) PWReleaseAssert((condition), (desc), (arg1), (arg2), (arg3), (arg4))
#define PWReleaseAssert5(condition, desc, arg1, arg2, arg3, arg4, arg5) PWReleaseAssert((condition), (desc), (arg1), (arg2), (arg3), (arg4), (arg5))
#define PWParameterReleaseAssert(condition) PWReleaseAssert((condition), @"Invalid parameter not satisfying: %s", #condition)
#endif

#if !defined(_PWCReleaseAssertBody)
#define PWCReleaseAssert1(condition, desc, arg1) PWCReleaseAssert((condition), (desc), (arg1))
#define PWCReleaseAssert2(condition, desc, arg1, arg2) PWCReleaseAssert((condition), (desc), (arg1), (arg2))
#define PWCReleaseAssert3(condition, desc, arg1, arg2, arg3) PWCReleaseAssert((condition), (desc), (arg1), (arg2), (arg3))
#define PWCReleaseAssert4(condition, desc, arg1, arg2, arg3, arg4) PWCReleaseAssert((condition), (desc), (arg1), (arg2), (arg3), (arg4))
#define PWCReleaseAssert5(condition, desc, arg1, arg2, arg3, arg4, arg5) PWCReleaseAssert((condition), (desc), (arg1), (arg2), (arg3), (arg4), (arg5))
#define PWCParameterReleaseAssert(condition) PWCReleaseAssert((condition), @"Invalid parameter not satisfying: %s", #condition)
#endif

#endif


/* Non-vararg implementation of asserts (ignore) */
#if !defined(_PWReleaseAssertBody)
#define _PWReleaseAssertBody(condition, desc, arg1, arg2, arg3, arg4, arg5)	\
do {						\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
if (!(condition)) {				\
[[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd object:self file:[NSString stringWithUTF8String:__FILE__] \
lineNumber:__LINE__ description:(desc), (arg1), (arg2), (arg3), (arg4), (arg5)];	\
}						\
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
} while(0)
#endif
#if !defined(_PWCReleaseAssertBody)
#define _PWCReleaseAssertBody(condition, desc, arg1, arg2, arg3, arg4, arg5)	\
do {						\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
if (!(condition)) {				\
[[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] file:[NSString stringWithUTF8String:__FILE__] \
lineNumber:__LINE__ description:(desc), (arg1), (arg2), (arg3), (arg4), (arg5)];	\
}						\
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
} while(0)
#endif


/*
 * Asserts to use in Objective-C method bodies
 */

#if !defined(PWReleaseAssert)
#define PWReleaseAssert5(condition, desc, arg1, arg2, arg3, arg4, arg5)	\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWReleaseAssertBody((condition), (desc), (arg1), (arg2), (arg3), (arg4), (arg5)) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWReleaseAssert4(condition, desc, arg1, arg2, arg3, arg4)	\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWReleaseAssertBody((condition), (desc), (arg1), (arg2), (arg3), (arg4), 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWReleaseAssert3(condition, desc, arg1, arg2, arg3)	\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWReleaseAssertBody((condition), (desc), (arg1), (arg2), (arg3), 0, 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWReleaseAssert2(condition, desc, arg1, arg2)		\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWReleaseAssertBody((condition), (desc), (arg1), (arg2), 0, 0, 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWReleaseAssert1(condition, desc, arg1)		\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWReleaseAssertBody((condition), (desc), (arg1), 0, 0, 0, 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWReleaseAssert(condition, desc)			\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWReleaseAssertBody((condition), (desc), 0, 0, 0, 0, 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS
#endif

#if !defined(PWParameterReleaseAssert)
#define PWParameterReleaseAssert(condition)			\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWReleaseAssertBody((condition), @"Invalid parameter not satisfying: %s", #condition, 0, 0, 0, 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS
#endif


#if !defined(PWCReleaseAssert)
#define PWCReleaseAssert5(condition, desc, arg1, arg2, arg3, arg4, arg5)	\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWCReleaseAssertBody((condition), (desc), (arg1), (arg2), (arg3), (arg4), (arg5)) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWCReleaseAssert4(condition, desc, arg1, arg2, arg3, arg4)	\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWCReleaseAssertBody((condition), (desc), (arg1), (arg2), (arg3), (arg4), 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWCReleaseAssert3(condition, desc, arg1, arg2, arg3)	\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWCReleaseAssertBody((condition), (desc), (arg1), (arg2), (arg3), 0, 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWCReleaseAssert2(condition, desc, arg1, arg2)	\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWCReleaseAssertBody((condition), (desc), (arg1), (arg2), 0, 0, 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWCReleaseAssert1(condition, desc, arg1)		\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWCReleaseAssertBody((condition), (desc), (arg1), 0, 0, 0, 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWCReleaseAssert(condition, desc)			\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWCReleaseAssertBody((condition), (desc), 0, 0, 0, 0, 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS
#endif

#if !defined(PWCParameterReleaseAssert)
#define PWCParameterReleaseAssert(condition)			\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
_PWCReleaseAssertBody((condition), @"Invalid parameter not satisfying: %s", #condition, 0, 0, 0, 0) \
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS
#endif


/*

 PWNonFatal-Asserts
 
 Non-fatal asserts can be disabled via a global switch (PWSkipNonFatalAsserts). Code using them must be able to continue
 normally if the assert fails.
 
 They can be used for conditions which are expected to hold in normal operation and should be asserted at least in unit
 tests, but may fail in edge cases. Unit tests for said edge cases can use PWBlockNonFatalAsserts to allow the test to
 run without hitting the assert.

*/

#if !defined(NS_BLOCK_ASSERTIONS)

// Global controlling whether non-fatal asserts are skipped. Default is not to skip them.
extern BOOL PWSkipNonFatalAsserts;

// Macro to use in unit tests which want to disable non-fatal asserts.
#define PWBlockNonFatalAsserts do { PWSkipNonFatalAsserts = YES; } while (0)

#else

#define PWBlockNonFatalAsserts do {} while (0)

#endif


#if (defined(__STDC_VERSION__) && (199901L <= __STDC_VERSION__)) || (defined(__cplusplus) && (201103L <= __cplusplus))

#if !defined(NS_BLOCK_ASSERTIONS)

#if !defined(_PWNonFatalAssertBody)
#define PWNonFatalAssert(condition, desc, ...)	\
    do {				\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
	if (!PWSkipNonFatalAsserts && !(condition)) {		\
	    [[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd \
		object:self file:[NSString stringWithUTF8String:__FILE__] \
	    	lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
	}				\
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
    } while(0)
#endif

#if !defined(_PWCNonFatalAssertBody)
#define PWCNonFatalAssert(condition, desc, ...) \
    do {				\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
	if (!PWSkipNonFatalAsserts && !(condition)) {		\
	    [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] \
		file:[NSString stringWithUTF8String:__FILE__] \
	    	lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
	}				\
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
    } while(0)
#endif

#else // NS_BLOCK_ASSERTIONS defined

#if !defined(_PWNonFatalAssertBody)
#define PWNonFatalAssert(condition, desc, ...) do {} while (0)
#endif

#if !defined(_PWCNonFatalAssertBody)
#define PWCNonFatalAssert(condition, desc, ...) do {} while (0)
#endif

#endif

#if !defined(_PWNonFatalAssertBody)
#define PWNonFatalAssert1(condition, desc, arg1) PWNonFatalAssert((condition), (desc), (arg1))
#define PWNonFatalAssert2(condition, desc, arg1, arg2) PWNonFatalAssert((condition), (desc), (arg1), (arg2))
#define PWNonFatalAssert3(condition, desc, arg1, arg2, arg3) PWNonFatalAssert((condition), (desc), (arg1), (arg2), (arg3))
#define PWNonFatalAssert4(condition, desc, arg1, arg2, arg3, arg4) PWNonFatalAssert((condition), (desc), (arg1), (arg2), (arg3), (arg4))
#define PWNonFatalAssert5(condition, desc, arg1, arg2, arg3, arg4, arg5) PWNonFatalAssert((condition), (desc), (arg1), (arg2), (arg3), (arg4), (arg5))
#define PWNonFatalParameterAssert(condition) PWNonFatalAssert((condition), @"Invalid parameter not satisfying: %s", #condition)
#endif

#if !defined(_PWCNonFatalAssertBody)
#define PWCNonFatalAssert1(condition, desc, arg1) PWCNonFatalAssert((condition), (desc), (arg1))
#define PWCNonFatalAssert2(condition, desc, arg1, arg2) PWCNonFatalAssert((condition), (desc), (arg1), (arg2))
#define PWCNonFatalAssert3(condition, desc, arg1, arg2, arg3) PWCNonFatalAssert((condition), (desc), (arg1), (arg2), (arg3))
#define PWCNonFatalAssert4(condition, desc, arg1, arg2, arg3, arg4) PWCNonFatalAssert((condition), (desc), (arg1), (arg2), (arg3), (arg4))
#define PWCNonFatalAssert5(condition, desc, arg1, arg2, arg3, arg4, arg5) PWCNonFatalAssert((condition), (desc), (arg1), (arg2), (arg3), (arg4), (arg5))
#define PWCNonFatalParameterAssert(condition) PWCNonFatalAssert((condition), @"Invalid parameter not satisfying: %s", #condition)
#endif

#endif


/* Non-vararg implementation of asserts (ignore) */
#if !defined(NS_BLOCK_ASSERTIONS)
#if !defined(_PWNonFatalAssertBody)
#define _PWNonFatalAssertBody(condition, desc, arg1, arg2, arg3, arg4, arg5)	\
    do {						\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
	if (!PWSkipNonFatalAsserts && !(condition)) {				\
	    [[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd object:self file:[NSString stringWithUTF8String:__FILE__] \
	    	lineNumber:__LINE__ description:(desc), (arg1), (arg2), (arg3), (arg4), (arg5)];	\
	}						\
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
    } while(0)
#endif
#if !defined(_PWCNonFatalAssertBody)
#define _PWCNonFatalAssertBody(condition, desc, arg1, arg2, arg3, arg4, arg5)	\
    do {						\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
	if (!PWSkipNonFatalAsserts && !(condition)) {				\
	    [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithUTF8String:__PRETTY_FUNCTION__] file:[NSString stringWithUTF8String:__FILE__] \
	    	lineNumber:__LINE__ description:(desc), (arg1), (arg2), (arg3), (arg4), (arg5)];	\
	}						\
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
    } while(0)
#endif

#else

#if !defined(_PWNonFatalAssertBody)
#define _PWNonFatalAssertBody(condition, desc, arg1, arg2, arg3, arg4, arg5)
#endif
#if !defined(_PWCNonFatalAssertBody)
#define _PWCNonFatalAssertBody(condition, desc, arg1, arg2, arg3, arg4, arg5)
#endif
#endif


/*
 * Asserts to use in Objective-C method bodies
 */
 
#if !defined(PWNonFatalAssert)
#define PWNonFatalAssert5(condition, desc, arg1, arg2, arg3, arg4, arg5)	\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWNonFatalAssertBody((condition), (desc), (arg1), (arg2), (arg3), (arg4), (arg5)) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWNonFatalAssert4(condition, desc, arg1, arg2, arg3, arg4)	\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWNonFatalAssertBody((condition), (desc), (arg1), (arg2), (arg3), (arg4), 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWNonFatalAssert3(condition, desc, arg1, arg2, arg3)	\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWNonFatalAssertBody((condition), (desc), (arg1), (arg2), (arg3), 0, 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWNonFatalAssert2(condition, desc, arg1, arg2)		\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWNonFatalAssertBody((condition), (desc), (arg1), (arg2), 0, 0, 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWNonFatalAssert1(condition, desc, arg1)		\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWNonFatalAssertBody((condition), (desc), (arg1), 0, 0, 0, 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWNonFatalAssert(condition, desc)			\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWNonFatalAssertBody((condition), (desc), 0, 0, 0, 0, 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS
#endif

#if !defined(PWNonFatalParameterAssert)
#define PWNonFatalParameterAssert(condition)			\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWNonFatalAssertBody((condition), @"Invalid parameter not satisfying: %s", #condition, 0, 0, 0, 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS
#endif


#if !defined(PWCNonFatalAssert)
#define PWCNonFatalAssert5(condition, desc, arg1, arg2, arg3, arg4, arg5)	\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWCNonFatalAssertBody((condition), (desc), (arg1), (arg2), (arg3), (arg4), (arg5)) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWCNonFatalAssert4(condition, desc, arg1, arg2, arg3, arg4)	\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWCNonFatalAssertBody((condition), (desc), (arg1), (arg2), (arg3), (arg4), 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWCNonFatalAssert3(condition, desc, arg1, arg2, arg3)	\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWCNonFatalAssertBody((condition), (desc), (arg1), (arg2), (arg3), 0, 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWCNonFatalAssert2(condition, desc, arg1, arg2)	\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWCNonFatalAssertBody((condition), (desc), (arg1), (arg2), 0, 0, 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWCNonFatalAssert1(condition, desc, arg1)		\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWCNonFatalAssertBody((condition), (desc), (arg1), 0, 0, 0, 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS

#define PWCNonFatalAssert(condition, desc)			\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWCNonFatalAssertBody((condition), (desc), 0, 0, 0, 0, 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS
#endif

#if !defined(PWCNonFatalParameterAssert)
#define PWCNonFatalParameterAssert(condition)			\
	__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
    _PWCNonFatalAssertBody((condition), @"Invalid parameter not satisfying: %s", #condition, 0, 0, 0, 0) \
        __PRAGMA_POP_NO_EXTRA_ARG_WARNINGS
#endif

