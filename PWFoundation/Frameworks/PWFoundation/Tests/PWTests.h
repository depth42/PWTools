//
//  PWTests.h
//  PWFoundation
//
//  Created by Frank Illenberger on 01.08.13.
//
//

// The methods in this class should be used by non AppKit-apps like daemons which want their tests to
// be performed when they are run with the XCTest framework inject, like XCode does when performing its test action.
@interface PWTests : NSObject

// Returns whether the XCTesting framework is available.
// Can be used by apps to determine whether they are run within a test context.
+ (BOOL)areTestsAvailable;

// This method is only useful for Mac applications which do not link against the AppKit framework.
// For them, the standard way of injecting test bundles into an application does start the tests.
// This method manually starts the tests.
+ (void)runTests;

@end
