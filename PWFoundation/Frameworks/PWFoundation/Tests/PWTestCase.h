//
//  PWTestCase.h
//  PWFoundation
//
//  Created by Kai Brüning on 7.11.11.
//
//

#import <XCTest/XCTest.h>
#import <PWFoundation/PWSDKAvailability.h>
#import <PWFoundation/PWDispatch.h>
#import <PWFoundation/NSObject-PWExtensions.h>
#import <PWFoundation/PWDebugOptionMacros.h>

NS_ASSUME_NONNULL_BEGIN

DEBUG_OPTION_DECLARE_GROUP (PWFoundationDebugGroup)
DEBUG_OPTION_DECLARE_SWITCH_D (PWDisableTimeoutsInTests)

// A macro to use with methods of the form -xxxAtLocation:(NSString*)filePath line:(NSUInteger)lineNumber, which can
// be called xxxAtLocation:SOURCE_LOCATION.
#define SOURCE_LOCATION @__FILE__ line:__LINE__

@interface PWTestCase : XCTestCase

// To be overwritten by sub classes to perform checks after the autorelease pool around the test has been drained.
- (void) afterAutoreleaseDrain;

// Expected Exceptions

- (void) setExpectedExceptionWithClass:(nullable Class)exceptionClass name:(nullable NSString*)exceptionName;

- (void) setAssertExpected;

- (void) clearExpectedException;

#pragma mark - Timeout Values

// Standard values for timeouts in tests.
// Using these instead of literal values has the advantage that the actual timeout can be influenced, e.g. by
// timeoutFactor or the debug option PWDisableTimeoutsInTests.

@property (nonatomic, readonly)     NSTimeInterval  shortTimeout;   // 2 seconds * timeoutFactor
@property (nonatomic, readonly)     NSTimeInterval  normalTimeout;  // 5 seconds * timeoutFactor
@property (nonatomic, readonly)     NSTimeInterval  longTimeout;    // 20 seconds * timeoutFactor

@property (nonatomic, readwrite)    double          timeoutFactor;  // reset to 1 -setUp

#pragma mark - Asynchronous Testing

// *** assertions for UI testing with asynchronous changes

// blocks the main queue until the given objects keypath changes
- (void)assertChangeInKeyPath:(NSString*)keyPath
                     ofObject:(id)object;

// same as above but with additional block being called _before_ the main queue blocks
- (void)assertChangeInKeyPath:(NSString*)keyPath
                     ofObject:(id)object
          whenPerformingBlock:(nullable PWDispatchBlock)block;

// same as above with additional predicate that _alternatively_ can un-block the main queue
- (void)assertChangeInKeyPath:(NSString*)keyPath
                     ofObject:(id)object
                    predicate:(nullable BOOL(^)())predicate
          whenPerformingBlock:(nullable PWDispatchBlock)block;

// alternative method with arbitrary value block
// returns true when successful
- (BOOL)waitWithTimeout:(NSTimeInterval)timeout untilCountDidChange:(NSUInteger(^)(void))block;
- (BOOL)waitWithTimeout:(NSTimeInterval)timeout untilObjectDidChange:(id(^)(void))block;
- (BOOL)waitWithTimeout:(NSTimeInterval)timeout untilPassingTest:(BOOL(^)(void))block;

- (void)waitWithTimeout:(NSTimeInterval)timeout
             atLocation:(NSString*)filePath line:(NSUInteger)lineNumber
    untilCountDidChange:(NSUInteger(^)(void))block;

- (void)waitWithTimeout:(NSTimeInterval)timeout
             atLocation:(NSString*)filePath line:(NSUInteger)lineNumber
   untilObjectDidChange:(id(^)(void))block;

// starts tracking object value brefore action block is called
- (void) waitWithTimeout:(NSTimeInterval)timeout
              atLocation:(NSString*)filePath line:(NSUInteger)lineNumber
             actionBlock:(PWDispatchBlock)actionBlock
    untilObjectDidChange:(id(^)(void))block;

- (void)waitWithTimeout:(NSTimeInterval)timeout
             atLocation:(NSString*)filePath line:(NSUInteger)lineNumber
       untilPassingTest:(BOOL(^)(void))block;

@property (nonatomic, readonly, copy)   NSURL* temporaryDirectoryURL;
+ (NSURL*)temporaryDirectoryURL;

// Whether the temporary directory is deleted by -reset, which is called by -tearDown.
// If NO, the temporary directory is  deleted in +setup only.
// Default is YES.
+ (BOOL) deleteTemporaryDirectoryAfterEachTest;

- (void) reset;
@end


#define PWXCTAssertEqualNumberObjects(a,b,accuracy) \
    XCTAssertEqualWithAccuracy([a doubleValue], [b doubleValue], accuracy);

// Variants of XCTAssertThrows et al macros with -setExpectedExceptionWithClass:... at the start and
// -clearExpectedException at the end.

// Unfortunately I do not know a method to update an existing macro under the same name short of completely replacing
// it. Copy/paste from system headers (XCTestAssertions.h, in this case) is not nice, but these macros are not
// likely to change frequently.
// Testing the __clang_major__ version is done to detect Xcode 6, which first changed the format of these macros from Xcode 5.

#if __clang__ && (__clang_major__ >= 6)

#define XCTAssertEqualObjectsFuzzy(expression1, expression2, ...) \
    XCTAssertTrue(PWEqualObjectsFuzzy(expression1, expression2, YES), __VA_ARGS__)

#undef XCTAssertThrows
#define XCTAssertThrows(expression, ...) \
do { \
    [self setExpectedExceptionWithClass:Nil name:nil]; \
    _XCTPrimitiveAssertThrows(self, expression, @#expression, __VA_ARGS__); \
    [self clearExpectedException]; \
} while (0)


#undef XCTAssertThrowsSpecific
#define XCTAssertThrowsSpecific(expression, exception_class, ...) \
do { \
    [self setExpectedExceptionWithClass:exception_class.class name:nil]; \
    _XCTPrimitiveAssertThrowsSpecific(self, expression, @#expression, exception_class, __VA_ARGS__); \
    [self clearExpectedException]; \
} while (0)


#undef XCTAssertThrowsSpecificNamed
#define XCTAssertThrowsSpecificNamed(expression, exception_class, exception_name, ...) \
do { \
    [self setExpectedExceptionWithClass:exception_class.class name:exception_name]; \
    _XCTPrimitiveAssertThrowsSpecificNamed(self, expression, @#expression, exception_class, exception_name, __VA_ARGS__); \
    [self clearExpectedException]; \
} while (0)

#define XCTAssertAsserts(expression, ...) \
do { \
    [self setAssertExpected]; \
    _XCTPrimitiveAssertThrows(self, expression, @#expression, __VA_ARGS__); \
    [self clearExpectedException]; \
} while (0)

#else

#if UXTARGET_IOS9
    #define PW_XCTPrimitiveAssertThrows(expression, format...) _XCTPrimitiveAssertThrows(self, expression, @#expression, format)
#else
    #define PW_XCTPrimitiveAssertThrows(expression, format...) _XCTPrimitiveAssertThrows(expression, format)
#endif


#undef XCTAssertThrows
#define XCTAssertThrows(expression, format...) \
do { \
    PW_XCTPrimitiveAssertThrows(expression, ## format); \
    [self clearExpectedException]; \
} while (0)


#undef XCTAssertThrowsSpecific
#define XCTAssertThrowsSpecific(expression, specificException, format...) \
do { \
    [self setExpectedExceptionWithClass:specificException name:nil]; \
    _XCTPrimitiveAssertThrowsSpecific(expression, specificException, ## format); \
    [self clearExpectedException]; \
} while (0)


#undef XCTAssertThrowsSpecificNamed
#define XCTAssertThrowsSpecificNamed(expression, specificException, exception_name, format...) \
do { \
    [self setExpectedExceptionWithClass:specificException name:exception_name]; \
    _XCTPrimitiveAssertThrowsSpecificNamed(expression, specificException, exception_name, ## format); \
    [self clearExpectedException]; \
} while (0)

#endif

NS_ASSUME_NONNULL_END
