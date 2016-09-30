//
//  PWAssertionHandler.m
//  PWFoundation
//
//  Created by Kai Brüning on 3.8.12.
//
//

#import "PWAssertionHandler.h"
#import "PWLog.h"
#import "Intercept_objc_exception_throw.h"
#import <objc/runtime.h>
#import "PWDispatch.h"
#import "PWTestTesting.h"

#ifndef NDEBUG

@interface NSAssertionHandler (PWExtensions)
@property (nonatomic, readonly) BOOL isPWHandler;
@end

#pragma mark -

@implementation NSAssertionHandler (PWExtensions)

// The load method of any class could be used to install our intercept whenever PWFoundation is loaded.
+ (void) load
{
    // Patching the assertion handler takes about 90ms, so we only do it if the process was started from within Xcode
    // or the intercept is requested by passing -intercept_objc_exception_throw.
    // This greatly improves launch times for short-lived but often-started processes like MerlinServerUtil in debug builds.
    if(wasStartedFromXcode() || [NSUserDefaults.standardUserDefaults objectForKey:@"intercept_objc_exception_throw"])
    {
        intercept_objc_exception_throw();
        [self patchCurrentHandler];
    }
}

+ (NSAssertionHandler*) patched_currentHandler
{
    // this is not a recursion because of exchanged implementations
    NSAssertionHandler* handler = [self patched_currentHandler];

    // Create and install our handler on each thread for which it is requested.
    if (!handler.isPWHandler) {
        handler = [[PWAssertionHandler alloc] init];
        NSThread.currentThread.threadDictionary[NSAssertionHandlerKey] = handler;
    }
    return handler;
}

+ (void) patchCurrentHandler
{
    Method original = class_getClassMethod (self, @selector(currentHandler));
    NSAssert (original, nil);
    Method patched  = class_getClassMethod (self, @selector(patched_currentHandler));
    NSAssert (patched, nil);
    method_exchangeImplementations (original, patched);
}

- (BOOL) isPWHandler
{
    return NO;
}

- (BOOL) expectingAssert
{
    return NO;
}

- (void) setExpectingAssert:(BOOL)expectingAssert
{
}

@end

#pragma mark

@implementation PWAssertionHandler
{
    BOOL    _dontThrow;
    BOOL    _expectingAssert;
}

//@synthesize expectingAssert = _expectingAssert;

- (BOOL) isPWHandler
{
    return YES;
}

- (BOOL) expectingAssert
{
    return _expectingAssert;
}

- (void) setExpectingAssert:(BOOL)expectingAssert
{
    _expectingAssert = expectingAssert;
}

- (void) handleFailureInMethod:(SEL)selector
                        object:(id)object
                          file:(NSString*)fileName
                    lineNumber:(NSInteger)line
                   description:(NSString*)format,...
{
    NSString* description;
    if (format) {
        va_list argList;
        va_start (argList, format);
        description = [[NSString alloc] initWithFormat:format arguments:argList];
        va_end (argList);
    }

    //    Class objectClass = object_getClass (object);
    //    BOOL isClassMethod = class_isMetaClass (objectClass);
    //
    //    [self logFakeTestCaseAroundBlock:^{
    //        PWLog (@"*** %@ in %c[%@ %@], %@:%li\n",
    //               description ? description : @"Assertion failure",
    //               isClassMethod ? '+' : '-', isClassMethod ? object : objectClass, NSStringFromSelector (selector),
    //               fileName, line);
    //    }];
    [self raiseExceptionWithDescription:description];
}

- (void) handleFailureInFunction:(NSString*)functionName
                            file:(NSString*)fileName
                      lineNumber:(NSInteger)line
                     description:(NSString*)format,...
{
    NSString* description;
    if (format) {
        va_list argList;
        va_start (argList, format);
        description = [[NSString alloc] initWithFormat:format arguments:argList];
        va_end (argList);
    }

    //    [self logFakeTestCaseAroundBlock:^{
    //        PWLog (@"*** %@ in %@, %@:%li\n",
    //               description ? description : @"Assertion failure",
    //               functionName, fileName, line);
    //    }];
    [self raiseExceptionWithDescription:description];
}

- (void) raiseExceptionWithDescription:(NSString*)description
{
    // To support moving the programm counter behind the throw in the debugger, the throw must not be the only possible
    // exit of the method. So far this is the only reason for _dontThrow.
    if (!_dontThrow) {
        PWAssertionException* exception = [[PWAssertionException alloc] initWithReason:description userInfo:nil];
        // Very important: under -fobjc-arc-exceptions -[NSException raise] does not work, the exception object is
        // released and deallocated before being thrown (probably by the exception cleanup code).
        // The class raise-methods are not affected: with them ARC never sees the exception object.
        // Speculation: when seeing @throw the compiler knows what happens and does the right thing.

        // Set a breakpoint on this statement to intercept ASSERTs before the exception is thrown. Can even move the
        // programm counter to the end of the method to continue without throwing.
        @throw exception;
    }
}

// When an exception occurs outside of the synchronous performing of a SenTestCase (even during -setup or -tearDown)
// the performing of the test suite is aborted without any report of a failed test.
// To avoid missing such a situation in continous integration tools,
// we simulated the output of a failed test case containig the exception description.
//- (void)logFakeTestCaseAroundBlock:(PWDispatchBlock)block
//{
//    NSParameterAssert(block);
//    if(NSClassFromString(@"SenTestCase"))
//    {
//        printf("%s", [[NSString stringWithFormat:@"Test Suite 'PWAssertionHandlerTests' started at %@\n", [NSDate date]] UTF8String]);
//        printf("Test Case '-[PWAssertionHandler testAssertionFailed]' started.\n");
//        printf("PWAssertionHandler.m:1: error: -[PWAssertionHandler testAssertionFailed] : ");
//        block();
//        printf("Test Case '-[PWAssertionHandler testAssertionFailed]' failed (0.000 seconds).\n");
//        printf("%s", [[NSString stringWithFormat:@"Test Suite 'PWAssertionHandlerTests' finished at %@\n", [NSDate date]] UTF8String]);
//    }
//    else
//        block();
//}

@end

#pragma mark -

@implementation PWAssertionException

- (instancetype) initWithReason:(NSString*)reason userInfo:(NSDictionary*)userInfo
{
    return [super initWithName:NSInternalInconsistencyException reason:reason userInfo:userInfo];
}

@end

#endif
