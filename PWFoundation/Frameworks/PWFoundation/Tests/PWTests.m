//
//  PWTests.m
//  PWFoundation
//
//  Created by Frank Illenberger on 01.08.13.
//
//

#import "PWTests.h"
#import "PWTestTesting.h"
#include <dlfcn.h>

@implementation PWTests

+ (BOOL)areTestsAvailable
{
    return isRunningTests();
}

+ (void)runTests
{
    // Starting with Xcode7, there does not seem to be a public way of running applications tests in non-app kit applications.
    // The standard injection mechanism observes the NSApplicationDidFinishLaunchingNotification and registers a delayed action with the
    // run loop to start the tests.
    // Since we do not have a starting NSApplication, we have to simulate the notification.
    [NSNotificationCenter.defaultCenter postNotificationName:@"NSApplicationDidFinishLaunchingNotification"
                                                      object:nil
                                                    userInfo:nil];
    [NSRunLoop.currentRunLoop run];
}

@end
