//
//  PWSDKAvailability.h
//  PWFoundation
//
//  Created by Berbie on 14.02.2013.
//
//

// ** PLATTFORM SELECTORS
//
// more constistent and intentional switches for selection the current sdk/platform
#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)

    #define UXTARGET_IOS                1
    #define UXTARGET_IOS9               1

    #define UXTARGET_OSX                0

    #define UX_NOT_AVAILABLE_IOS        __AVAILABILITY_INTERNAL__IPHONE_NA_ios
    #define PWTEST_SKIP_IOS             return

    #define PWASSERT_NOT_AVAILABLE_IOS  NSCAssert(NO, @"NOT_AVAILABLE_IOS")

    #define UXBASE_CLASS(__OSX_class,__IOS_class) __IOS_class

#else
    #define UXTARGET_IOS                0
    #define UXTARGET_IOS9               0

    #define UXTARGET_OSX                1

    #define UX_NOT_AVAILABLE_IOS        ;
    #define PWTEST_SKIP_IOS             ;

    #define PWASSERT_NOT_AVAILABLE_OSX  NSCAssert(NO, @"NOT_AVAILABLE_OSX")

    #define UXBASE_CLASS(__OSX_class,__IOS_class) __OSX_class
#endif

#define UXTARGET_ALL (UXTARGET_OSX || UXTARGET_IOS) // assumes (OSX10_8 and IOS7_0)
#define UXTARGET_NONE 1                             // case for not being available on any plattform

#define PWASSERT_NOT_AVAILABLE_ANY  NSCAssert(NO, @"NOT_AVAILABLE_ANY")

#define UXTARGET_SELECT(__OSX_value,__IOS_value) (UXTARGET_OSX ? __OSX_value : __IOS_value)

// ** MARKUP
//
// follows same idea as NS_DESIGNATED_INITIALIZER but for factories
#define PW_DESIGNATED_FACTORY

// ** ASSERTIONS
//
#define PWAssert(a)                 NSAssert(a,nil)
#define PWParameterAssert(a)        NSParameterAssert(a)
#define PWAssertNotDisposed         NSAssert (!self.isDisposed, @"illegal use after dispose")

#import "PWLog.h"

// note that PWLog is being filtered for release builds
#if HAS_PWLOG

FOUNDATION_STATIC_INLINE void _PWTraceLog(const char* path, int line, id format, ...)
{
    NSString* file = [[[NSString alloc] initWithUTF8String:path] lastPathComponent];

    va_list argList;
    va_start (argList, format);
    
    NSString* text = [[NSString alloc] initWithFormat:format arguments:argList];
    PWLog(@"%@:%d %@\n", file, line, text);
    
    va_end (argList);
}

#define PWTrace                     PWLogn(@"<%p %@> %@", self, NSStringFromClass(self.class), NSStringFromSelector(_cmd))
#define PWTraceLog(...)             _PWTraceLog(__FILE__, __LINE__, __VA_ARGS__)
#define PWTraceLogValue(a)          PWTraceLog(@"%s: %@", #a, a)

#else

#define PWTrace                     ;
#define PWTraceLog(...)             do{}while(0)
#define PWTraceLogValue(a)          do{}while(0)

#endif

FOUNDATION_STATIC_INLINE void _PWReleaseTraceLog(const char* path, int line, id format, ...)
{
    NSString* file = [[[NSString alloc] initWithUTF8String:path] lastPathComponent];
    
    va_list argList;
    va_start (argList, format);
    
    NSString* text = [[NSString alloc] initWithFormat:format arguments:argList];
    NSLog(@"%@:%d %@\n", file, line, text);
    
    va_end (argList);
}

// may be used to log errors to the console that should also be logged in release builds
#define PWReleaseTraceLog(...)      _PWReleaseTraceLog(__FILE__, __LINE__, __VA_ARGS__);
#define PWReleaseTraceLogValue(a)   _PWReleaseTraceLog(__FILE__, __LINE__, @"%s: %@", #a, a);

// ** CLANG extensions available in IOS8/OSX10
//
// definition may be available from NSObjCRuntime.h
// At this location we only define the unavailable case
#ifndef NS_DESIGNATED_INITIALIZER
#define NS_DESIGNATED_INITIALIZER
#endif

// ** Interface Builder extenstions available in IOS8/OSX10
#ifndef IB_DESIGNABLE
#define IB_DESIGNABLE
#endif

#ifndef IBInspectable
#define IBInspectable
#endif

// ** SUBCLASSING SUPPORT
//
// Use this macro to state that this method is an override fully replacing the overridden implementation.
// Using this macro ensures that the compiler can detect changes of the signature of the overwritten method.
#define PWOVERRIDE_IGNORE(a)        while(0){(void)a;}

// Ensure that subclass implements method.
#define PWASSERT_ABSTRACT           NSCAssert(NO, @"ABSTRACT")

// ** REFACTORING MACROS
//
// For production should all be replaced by working code.
#define PWASSERT_NOT_YET_IMPLEMENTED NSCAssert(NO, @"NOT_YET_IMPLEMENTED")

NS_INLINE BOOL isAtLeastOSX10_12_iOS10_0()
{
#if UXTARGET_IOS
    return [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,0,0}];
#else
    return [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,12,0}];
#endif
}

NS_INLINE BOOL isAtLeastOSX10_11_iOS9_0()
{
#if UXTARGET_IOS
    return [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9,0,0}];
#else
    return [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,11,0}];
#endif
}

#if UXTARGET_IOS
NS_INLINE BOOL PWIsOperatingSystemAtLeastVersion_iOS10_0()
{
    return [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){10,0,0}];
}

NS_INLINE BOOL PWIsOperatingSystemAtLeastVersion_iOS9_0()
{
    return [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9,0,0}];
}

#define PWOperatingSystemIOS9Select(__ios9__, __other__) PWIsOperatingSystemAtLeastVersion_iOS9_0() ? (__ios9__) : (__other__)

#endif

