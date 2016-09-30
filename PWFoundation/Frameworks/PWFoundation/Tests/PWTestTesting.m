//
//  PWTestTesting.m
//  PWFoundation
//
//  Created by Kai Brüning on 30.7.14.
//
//

#import "PWTestTesting.h"
#import "PWDispatch.h"

#include <sys/sysctl.h> // isDebuggerAttached

BOOL isRunningTests()
{
    // Starting with Xcode 7, the test bundles are injected after the application has finished launching,
    // so to reliably test this we also check for an evironment variable which gets set by Xcode.
    // As this is private, we nevertheless keep the test for the XCTest class.

    static BOOL sIsRunningTests;
    PWDispatchOnce(^{
        sIsRunningTests = NSClassFromString (@"XCTest") != nil || NSProcessInfo.processInfo.environment[@"XCInjectBundle"];
    });
    return sIsRunningTests;
}

BOOL wasStartedFromXcode()
{
    // The environment variable XPC_SERVICE_NAME is set to a string containing "Xcode" in all cases launched from Xcode.
    // (app start, app unit test, framework test etc.)
    NSString* serviceName = NSProcessInfo.processInfo.environment[@"XPC_SERVICE_NAME"];
    if ([serviceName rangeOfString:@"Xcode" options:NSCaseInsensitiveSearch].length > 0)
        return YES;
    
#if UXTARGET_IOS
    // Under iOS the environment variable check above does not work, so we assume we were started from Xcode if a
    // debugger is attached.
    if (isDebuggerAttached())
        return YES;
#endif
    
    return NO;
}

BOOL isDebuggerAttached()
{
    static BOOL debuggerIsAttached = NO;
    
    PWDispatchOnce (^{
        struct kinfo_proc info;
        size_t info_size = sizeof(info);
        int name[4];
        
        name[0] = CTL_KERN;
        name[1] = KERN_PROC;
        name[2] = KERN_PROC_PID;
        name[3] = getpid();
        
        if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
            NSLog(@"ERROR: Checking for a running debugger via sysctl() failed: %s", strerror(errno));
            debuggerIsAttached = false;
        }
        
        if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0)
            debuggerIsAttached = true;
    });
    
    return debuggerIsAttached;
}
