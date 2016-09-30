/*
 *  PWTypes.h
 *  PWFoundation
 *
 *  Created by Kai on 3.6.10.
 *  Copyright 2010 ProjectWizards. All rights reserved.
 *
 *  Basic types which are of general use
 */

#import <Foundation/Foundation.h>

#pragma mark Integer Types

// Apples definition of NSInteger is consistent (32 bits under 32 bit architecture, 64 bits under 64 bit architecture),
// but at least as long as our code is not 64-bit only the use of NS[U]Integer just waists a lot of space. The larger
// range under 64 bits can not be used anyway as long as compatibility with the 32 bit version is a goal. For many
// variables a range beyond 32 bits won’t ever be needed anyway.
//
// PW[U]Integer and PW[U]Long approach the problem in another way.
// PW[U]Integer are the default integer types and should be used as long as at least 32 bits of range are enough for a
// variable. It happens to be defined as [unsigned] int under both current architectures, but this may change in
// future.
// PW[U]Long is guaranteed to be at least 64 bits wide. It should be used if that range is really needed.
//
// To avoid impedance mismatches, the use of NS[U]Integer as local variables is without problem. Real space savings
// come from using PW[U]Integer for instance variables.
//
// Note that with our compiler settings (NS_BUILD_32_LIKE_64=1), NSInteger is defined as long under both architectures.
// This makes is a different type from both PWInteger and PWLong under both architectures, which is good to enable the
// compiler to always detect mismatches when e.g. passing an integer by pointer.

typedef int PWInteger;
typedef unsigned int PWUInteger;

typedef long long PWLong;
typedef unsigned long long PWULong;

#define PWIntegerMax    INT_MAX
#define PWIntegerMin    INT_MIN
#define PWUIntegerMax   UINT_MAX

enum {PWNotFound = PWIntegerMax};

#pragma mark - Time

// Absolute time is the time interval (in seconds) since the reference date.
// The reference date (epoch) is 00:00:00 1 January 2001.
// Note: the OS provides CWAbsoluteTime with the same semantics, but we want to avoid using things from the Core
// Foundation namespace in public headers.
typedef NSTimeInterval PWAbsoluteTime;

// Two special absolute time values to mark points in the distant future or past.
// These values are more than 70 million years away from today.
// The carefully choosen values have an exact binary representation, which should make equality tests
// more robust. It even survives a conversion to float and back unchanged.
// We intentionally did not use the constants used by NSDate.distantFuture/distantPast, because these are actually not
// that distant.
#define PW_DISTANT_PAST  -2251799813685248.0
#define PW_DISTANT_FUTURE 2251799813685248.0

// Time interval since midnight.
typedef NSTimeInterval PWTimeOfDay;

#pragma mark - Extended Boolean

// It is helpful to always use the same values when a mixed state for a boolean value is needed. Apple’s NSMixedState
// unfortunately lives in AppKit. Of course we carefully picked the same value as Apple did.

enum {
    PWNo            = NO,       // = NSOffState
    PWYes           = YES,      // = NSOnState
    PWBoolMixed     = -1,       // = NSMixedState
    PWBoolUndefined = -2        // sometimes useful when collecting values
};
typedef PWInteger PWExtendedBool;

#pragma mark - PWCOMPARE Macro

#define PWCOMPARE(A,B) ({ __typeof__(A) __a = (A); __typeof__(B) __b = (B); __a == __b ? NSOrderedSame : (__a < __b ? NSOrderedAscending : NSOrderedDescending); })

#pragma mark - Min & Max

#define PWMINMAX(MIN,V,MAX) ({ __typeof__(MIN) __min = (MIN); __typeof__(MAX) __max = (MAX); __typeof__(V) __v = (V); __v < __min ? __min : (__v > __max ? __max : __v); })

#pragma mark - Integer-based Point and Size

typedef struct PWIntegerSize
{
    PWUInteger width;
    PWUInteger height;
} PWIntegerSize;

NS_INLINE PWIntegerSize PWIntegerSizeMake(PWUInteger width, PWUInteger height)
{
    PWIntegerSize size;
    size.width = width;
    size.height = height;
    return size;
}

NS_INLINE BOOL PWIntegerSizeEqualToSize(PWIntegerSize s1, PWIntegerSize s2)
{
    return s1.width == s2.width && s1.height == s2.height;
}

typedef struct PWUIntegerPoint
{
    PWUInteger x;
    PWUInteger y;
} PWUIntegerPoint;

NS_INLINE PWUIntegerPoint PWUIntegerPointMake(PWUInteger x, PWUInteger y)
{
    PWUIntegerPoint point;
    point.x = x;
    point.y = y;
    return point;
}

NS_INLINE BOOL PWUIntegerPointEqualToPoint(PWUIntegerPoint p1, PWUIntegerPoint p2)
{
    return p1.x == p2.x && p1.y == p2.y;
}

typedef struct PWUIntegerRect
{
    PWUIntegerPoint origin;
    PWIntegerSize   size;
} PWUIntegerRect;

NS_INLINE PWUIntegerRect PWUIntegerRectMake(PWUInteger x, PWUInteger y, PWUInteger width, PWUInteger height)
{
    PWUIntegerRect rect;
    rect.origin.x = x;
    rect.origin.y = y;
    rect.size.width = width;
    rect.size.height = height;
    return rect;
}

NS_INLINE BOOL PWUIntegerRectEqualToRect(PWUIntegerRect r1, PWUIntegerRect r2)
{
    return PWIntegerSizeEqualToSize(r1.size, r2.size) && PWUIntegerPointEqualToPoint(r1.origin, r2.origin);
}

typedef struct PWFloatInterval
{
    CGFloat start;
    CGFloat end;
} PWFloatInterval;

NS_INLINE PWFloatInterval PWFloatIntervalMake(CGFloat start, CGFloat end)
{
    PWFloatInterval interval;
    if(start < end)
    {
        interval.start = start;
        interval.end   = end;
    }
    else
    {
        interval.start = end;
        interval.end   = start;
    }
    return interval;
}

NS_INLINE CGFloat PWFloatIntervalGetLength(PWFloatInterval interval)
{
    return interval.end - interval.start;
}

NS_INLINE CGFloat PWFloatIntervalGetCenter(PWFloatInterval interval)
{
    return 0.5*(interval.start + interval.end);
}

NS_INLINE BOOL PWFloatIntervalEqualToInterval(PWFloatInterval intervalA, PWFloatInterval intervalB)
{
    return (intervalA.start == intervalB.start) && (intervalA.end == intervalB.end);
}

// Note: Does not care about zero-length intervals.
NS_INLINE PWFloatInterval PWFloatIntervalUnion(PWFloatInterval intervalA, PWFloatInterval intervalB)
{
    PWFloatInterval interval;
    interval.start = MIN(intervalA.start, intervalB.start);
    interval.end = MAX(intervalA.end, intervalB.end);
    return interval;
}

NS_INLINE CGFloat PWFloatIntervalGetLengthOfPositivePart(PWFloatInterval interval)
{
    return MAX(interval.end, 0.0) - MAX(interval.start, 0.0);
}

NS_INLINE CGFloat PWFloatIntervalGetLengthOfNegativePart(PWFloatInterval interval)
{
    return MIN(interval.end, 0.0) - MIN(interval.start, 0.0);
}

NS_INLINE BOOL PWFloatIntervalIntersectsInterval(PWFloatInterval intA, PWFloatInterval intB)
{
    return (intA.start < intB.end) && (intA.end > intB.start);
}

#pragma mark - Duration Unit

typedef NS_ENUM (PWInteger, PWDurationUnit)
{
    PWDurationNoUnit    =  0,
    PWDurationSeconds   =  1,
    PWDurationMinutes   =  2,
    PWDurationHours     =  3,
    PWDurationDays      =  4,
    PWDurationWeeks     =  5,
    PWDurationMonths    =  6,
    PWDurationQuarters  =  7,
    PWDurationYears     =  8,
};

#pragma mark - ARC Support

#ifdef __cplusplus
extern "C" {
#endif

    // Declaration of the private objc_autorelease() function. Of course this function is normally declared taking and
    // returning id, but for the use in CFAutoRelease this signature is the one which produces both correct code and no
    // analyzer warnings.
    
CF_IMPLICIT_BRIDGING_ENABLED

CFTypeRef objc_autorelease(CFTypeRef __attribute__((cf_consumed)) value);

CF_IMPLICIT_BRIDGING_DISABLED


#ifdef __cplusplus
}
#endif

// CFAutoRelease autoreleases the passed in Core Foundation object and returns it as Core Foundation type 'cfType'.
// Note that all Core Foundation objects can be treated as NSObjects for memory management.
#define CFAutoRelease(cfType, cfObj) ((cfType)objc_autorelease(cfObj))

// CFTransferToARC turns a CF object into an ARCed object, transfering a retain of the CF object to ARC. This is
// suitable for CF objects obtained by Create or Copy functions.
// IMPORTANT: cfARCType must be a typedef with NSObjectBehaviour. If the method or function using this macro returns
// the object in question, its return type must be the same type. Otherwise an underretain results, which is currently
// (Xcode 5 DP) not detected by the analyzer.
#define CFTransferToARC(cfARCType, cfObj) ((__bridge cfARCType)(__bridge_transfer id)(cfObj))

// To synthesize properties with core foundation objects.
#define NSObjectBehaviour __attribute__((NSObject))

// NSObjectBehaviour does only work when it is combined with its type in a typedef. Otherwise the compiler
// will not create the correct retain statements. Therefore we define the following types:
typedef NSObjectBehaviour CFTypeRef         PWCFTypeObject;
typedef NSObjectBehaviour CGColorRef        PWCGColorObject;
typedef NSObjectBehaviour CGGradientRef     PWCGGradientObject;
typedef NSObjectBehaviour CGImageRef        PWCGImageObject;
typedef NSObjectBehaviour CGMutablePathRef  PWCGMutablePathObject;
typedef NSObjectBehaviour CGPathRef         PWCGPathObject;
typedef NSObjectBehaviour CTFontRef         PWCTFontObject;
typedef NSObjectBehaviour CTLineRef         PWCTLineObject;
typedef NSObjectBehaviour CTFrameRef        PWCTFrameObject;

