//
//  PWTestCase.m
//  PWFoundation
//
//  Created by Kai Brüning on 7.11.11.
//
//

#import "PWTestCase.h"
#import <PWFoundation/PWDispatch.h>
#import <PWFoundation/Intercept_objc_exception_throw.h>
#import <PWFoundation/PWAssertionHandler.h>
#import <PWFoundation/PWDispatchQueueGraph.h>
#import <PWFoundation/PWDebugOptionMacros.h>
#import <PWFoundation/PWTestTesting.h>
#import <PWFoundation/PWAsserts.h>
#import <PWFoundation/NSCalendar-PWExtensions.h>
#import <PWFoundation/NSBundle-PWExtensions.h>

NS_ASSUME_NONNULL_BEGIN

DEBUG_OPTION_DEFINE_SWITCH_D (PWDisableTimeoutsInTests, PWFoundationDebugGroup,
                              @"Disable timeout when waiting for expectations", @"",
                              DEBUG_OPTION_DEFAULT_OFF, DEBUG_OPTION_PERSISTENT)


@interface NSFileManager (METest)
- (NSArray*)pwtest_URLsForDirectory:(NSSearchPathDirectory)directory inDomains:(NSSearchPathDomainMask)domainMask;
@end

#pragma mark

@implementation PWTestCase

static BOOL                sExpectingException;
static Class _Nullable     sExpectedExceptionClass;
static NSString *_Nullable sExpectedExceptionName;

+ (void) setUp
{
    // Enable use of debug options for the test.
    // This is done as early as possible to have the settings available for anything which follows.
    // Debug options can be controlled by command line parameters, which should go before the -SenTest parameters.
    static PWDebugOptionGroup* rootGroup;
    PWDispatchOnce(^{
        rootGroup = [PWRootDebugOptionGroup createRootGroup];
    });
    
#if (0 && UXTARGET_IOS)
    // optional switch on IOS because we can´t manually set PWDisableTimeoutsInTests
    PWDisableTimeoutsInTests = isDebuggerAttached();
#endif

    [super setUp];

    [self ensureMockedAppSupportDirectories];
    [self deleteTemporaryDirectory];

    // Ensure shared config coordinators use the correct document package class.
}

- (void) setUp
{
    [super setUp];
#if PWDISPATCH_USE_QUEUEGRAPH
    [PWDispatchQueueGraph.sharedGraph reset];
#endif
    _timeoutFactor = 1.0;
}

- (void) tearDown
{
    [self reset];
    [super tearDown];
}

- (void)reset
{
    if (self.class.deleteTemporaryDirectoryAfterEachTest)
        [self.class deleteTemporaryDirectory];
}

- (void) invokeTest
{
    @autoreleasepool {
        [super invokeTest];
    }

    [self afterAutoreleaseDrain];
}

- (void) afterAutoreleaseDrain
{
    // for sub class overrides

#if PWDISPATCH_USE_QUEUEGRAPH
    XCTAssertTrue ([PWDispatchQueueGraph.sharedGraph checkTreeStructure],
                   @"Cycle detected in dispatch queue graph of %@", self);
#endif
}

#pragma mark - Temporary Directory

+ (BOOL) deleteTemporaryDirectoryAfterEachTest
{
    return YES;
}

+ (void)deleteTemporaryDirectory
{
    __block NSError* error;
    NSFileManager* manager = NSFileManager.defaultManager;
    // Sometimes deleting the temporary directory fails here because some async cleanup with file coordination from
    // previous tests is interfering. In this case we retry for a while.
    NSURL* tempDirURL = self.temporaryDirectoryURL;
    BOOL tempDirDelete = [self waitWithTimeout:10.0 untilPassingTest:^BOOL {
        return ![manager fileExistsAtPath:tempDirURL.path]
             || [manager removeItemAtURL:tempDirURL error:&error];
    }];
    NSAssert (tempDirDelete, @"%@", error);
}

+ (NSURL*)temporaryDirectoryURL
{
    static NSURL* tempDir;
    PWDispatchOnce (^{
        // Note: docu suggests -[NSFileManager URLForDirectory:inDomain:appropriateForURL:create:error:] as replacement
        // for NSTemporaryDirectory(), but this does not work (NSItemReplacementDirectory is the only remotely temporary-
        // related value and does not really work as temporary directory, see Google).
        tempDir = [[[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:NSProcessInfo.processInfo.processName] URLByAppendingPathComponent:@"_PWTestCase"];
    });

    NSFileManager* manager = NSFileManager.defaultManager;
    if(![manager fileExistsAtPath:tempDir.path])
    {
        NSError* error;
        BOOL success = [manager createDirectoryAtURL:tempDir
                         withIntermediateDirectories:YES
                                          attributes:nil
                                               error:&error];
        PWReleaseAssert (success, @"Could not create temporary directory at %@ with %@", tempDir, error);
    }

    return tempDir;
}

- (NSURL*)temporaryDirectoryURL
{
    return self.class.temporaryDirectoryURL;
}

#pragma mark - Expected Exceptions

- (void) setExpectedExceptionWithClass:(nullable Class)exceptionClass name:(nullable NSString*)exceptionName
{
    PWDispatchOnce(^{
        registerExpectedExceptionFilter (^(NSException* exception) {
            if (!sExpectingException)
                return NO;
            if (sExpectedExceptionClass && ![exception isKindOfClass:sExpectedExceptionClass])
                return NO;
            if (sExpectedExceptionName && ![exception.name isEqualToString:sExpectedExceptionName])
                return NO;
            
        #ifndef NS_BLOCK_ASSERTIONS
            // Always break on assertions, unless specifically expected.
            if (   sExpectedExceptionClass != PWAssertionException.class
                && [exception isKindOfClass:PWAssertionException.class])
                return NO;
        #endif

            return YES; // that is, throw the exception without breaking in the debugger
        });
    });
    
    sExpectingException     = YES;
    sExpectedExceptionClass = exceptionClass;
    sExpectedExceptionName  = [exceptionName copy];
}

- (void) setAssertExpected
{
#ifndef NDEBUG
    [self setExpectedExceptionWithClass:PWAssertionException.class name:nil];
    NSAssertionHandler.currentHandler.expectingAssert = YES;
#endif
}

- (void) clearExpectedException
{
    sExpectingException     = NO;
    sExpectedExceptionClass = Nil;
    sExpectedExceptionName  = nil;
#ifndef NDEBUG
    NSAssertionHandler.currentHandler.expectingAssert = NO;
#endif
}

#pragma mark - value change asserts

- (void)assertChangeInKeyPath:(NSString*)keyPath
                     ofObject:(id)object
{
    [self assertChangeInKeyPath:keyPath ofObject:object predicate:nil whenPerformingBlock:nil];
}

- (void)assertChangeInKeyPath:(NSString*)keyPath
                     ofObject:(id)object
          whenPerformingBlock:(nullable PWDispatchBlock)block
{
    [self assertChangeInKeyPath:keyPath ofObject:object predicate:nil whenPerformingBlock:block];
}

- (void)assertChangeInKeyPath:(NSString*)keyPath
                     ofObject:(id)object
                    predicate:(nullable BOOL(^)())predicate
          whenPerformingBlock:(nullable PWDispatchBlock)block
{
    NSParameterAssert(keyPath);
    NSParameterAssert(object);
    
    __block BOOL done = NO;
    PWDispatchObserver* observer = [object addObserverForKeyPath:keyPath
                                                         options:0
                                                   dispatchQueue:nil
                                                   synchronously:YES
                                                      usingBlock:^(NSString* blockKeyPath, id obj, NSDictionary* change)
                                    {
                                        if(!predicate || predicate())
                                            done = YES;
                                    }];
    
    if (block)
        block();
    
    NSTimeInterval timeoutInterval = 10.0;
    NSTimeInterval iterationInterval = 0.02;
    
    NSRunLoop* loop = NSRunLoop.currentRunLoop;
    NSDate* startDate = [NSDate date];
    while(!done && -startDate.timeIntervalSinceNow < timeoutInterval)
        [loop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:iterationInterval]];
    
    [observer dispose];
    XCTAssertTrue(done);
}

#pragma mark - Timeout Values

- (NSTimeInterval) shortTimeout
{
    return PWDisableTimeoutsInTests ? SECONDS_PER_WEEK : 2.0 * _timeoutFactor;
}

- (NSTimeInterval) normalTimeout
{
    return PWDisableTimeoutsInTests ? SECONDS_PER_WEEK : 5.0 * _timeoutFactor;
}

- (NSTimeInterval) longTimeout
{
    return PWDisableTimeoutsInTests ? SECONDS_PER_WEEK : 20.0 * _timeoutFactor;
}

#pragma mark - Asynchronous Testing

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout untilCountDidChange:(NSUInteger(^)(void))block;
{
    NSUInteger oldValue = block();
    return [self waitWithTimeout:timeout untilPassingTest:^{ return (BOOL)(oldValue != block()); }];
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout untilObjectDidChange:(id(^)(void))block;
{
    id oldValue = block();
    return [self waitWithTimeout:timeout untilPassingTest:^{ return (BOOL)(oldValue != block()); }];
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout actionBlock:(PWDispatchBlock)actionBlock untilObjectDidChange:(id(^)(void))block;
{
    id oldValue = block();
    actionBlock();
    return [self waitWithTimeout:timeout untilPassingTest:^{ return (BOOL)(oldValue != block()); }];
}

// derived from PWLeakChecker::checkLivingInstances
+ (BOOL)waitWithTimeout:(NSTimeInterval)timeout untilPassingTest:(BOOL(^)(void))block
{
    PWParameterAssert(block);

    if (PWDisableTimeoutsInTests)
        timeout = SECONDS_PER_WEEK; // should be long enough

    BOOL done = block();
    CFTimeInterval interval = 0.0005;
    CFTimeInterval totalInterval = 0.0;
    
    while(!done && totalInterval < timeout)
    {
        // Delayed run-loop actions may autorelease objects, we want to deallocate them after running the loop,
        // therefore we wrap the run in an autorelease pool.
        @autoreleasepool {
            CFRunLoopRunInMode (kCFRunLoopDefaultMode,
                                /*seconds =*/interval,
                                /*returnAfterSourceHandled =*/NO);
        }

        done = block();

        totalInterval += interval; // is not an exact measure of time, but good enough
        if(interval < 0.5)
            interval *= 2;
    }
    
    return done;
}

- (BOOL)waitWithTimeout:(NSTimeInterval)timeout untilPassingTest:(BOOL(^)(void))block
{
    return [self.class waitWithTimeout:timeout untilPassingTest:block];
}

- (void) waitWithTimeout:(NSTimeInterval)timeout
              atLocation:(NSString*)filePath line:(NSUInteger)lineNumber
     untilCountDidChange:(NSUInteger(^)(void))block
{
    if (![self waitWithTimeout:timeout untilCountDidChange:block])
        [self recordFailureWithDescription:@"Wait timed out" inFile:filePath atLine:lineNumber expected:YES];
}

- (void) waitWithTimeout:(NSTimeInterval)timeout
              atLocation:(NSString*)filePath line:(NSUInteger)lineNumber
    untilObjectDidChange:(id(^)(void))block
{
    if (![self waitWithTimeout:timeout untilObjectDidChange:block])
        [self recordFailureWithDescription:@"Wait timed out" inFile:filePath atLine:lineNumber expected:YES];
}

- (void) waitWithTimeout:(NSTimeInterval)timeout
              atLocation:(NSString*)filePath line:(NSUInteger)lineNumber
             actionBlock:(PWDispatchBlock)actionBlock
    untilObjectDidChange:(id(^)(void))block
{
    if (![self waitWithTimeout:timeout actionBlock:actionBlock untilObjectDidChange:block])
        [self recordFailureWithDescription:@"Wait timed out" inFile:filePath atLine:lineNumber expected:YES];
}

- (void) waitWithTimeout:(NSTimeInterval)timeout
              atLocation:(NSString*)filePath line:(NSUInteger)lineNumber
        untilPassingTest:(BOOL(^)(void))block
{
    if (![self waitWithTimeout:timeout untilPassingTest:block])
        [self recordFailureWithDescription:@"Wait timed out" inFile:filePath atLine:lineNumber expected:YES];
}

+ (void)deleteAppSupportDirectory
{
    NSError* error;
    // Delete temporary directory
    NSFileManager* manager = NSFileManager.defaultManager;
    NSURL* appSupportFolderURL = [NSBundle URLsToApplicationSupportFolderForDomains:NSUserDomainMask].firstObject;
    if([manager fileExistsAtPath:appSupportFolderURL.path])
        NSAssert([manager removeItemAtURL:appSupportFolderURL error:&error], @"%@", error);
}

// For testing purposes the Application Support Directory returned by
// NSFileManager should be in the temporary directory. This prevents the
// tests from interfering with app settings already made on a machine.
+ (void)ensureMockedAppSupportDirectories
{
    PWDispatchOnce(^{
        [NSFileManager exchangeInstanceMethod:@selector(URLsForDirectory:inDomains:)
                                   withMethod:@selector(pwtest_URLsForDirectory:inDomains:)];
    });
}

@end

#pragma mark

@implementation NSFileManager (METest)

- (NSArray*)pwtest_URLsForDirectory:(NSSearchPathDirectory)directory
                          inDomains:(NSSearchPathDomainMask)domainMask
{
    // Note: This replacement currently does not deal with masks containing more than one set bit
    if(directory == NSApplicationSupportDirectory)
    {
        if(domainMask == NSUserDomainMask)
            return @[[PWTestCase.temporaryDirectoryURL URLByAppendingPathComponent:@"User/AppSupport"]];
        else if(domainMask == NSLocalDomainMask)
            return @[[PWTestCase.temporaryDirectoryURL URLByAppendingPathComponent:@"Local/AppSupport"]];
        else if(domainMask == NSNetworkDomainMask)
            return @[[PWTestCase.temporaryDirectoryURL URLByAppendingPathComponent:@"Network/AppSupport"]];
    }
    return [self pwtest_URLsForDirectory:directory inDomains:domainMask];
}

@end

NS_ASSUME_NONNULL_END
