//
//  NSDate-PWExtensions.h
//  Merlin
//
//  Created by Frank Illenberger on 30.07.05.
//
//

#import <PWFoundation/PWValueTypes.h>
#import <PWFoundation/PWComparing.h>

@class PWISODateFormatter;

@interface NSDate (PWExtensions) <PWComparing>

// Forces +date to return 'forcedDate‘ instead of the current date. Sending the message with nil for 'forcedDate'
// resets to using the current date again.
// Meant for use by unit tests.
+ (void) setForcedNowToDate:(NSDate*)forcedDate;
+ (void) setSystemNowInGMTToDate:(NSDate*)forcedDate;   

// Returns the date rounded to full seconds.
// Useful to ensure round-trip fidelity for xml coding, which so far only includes full seconds.
@property (nonatomic, readonly, copy) NSDate *dateByRoundingToSeconds;

// The following methods should not be used for new developments. They are still used by the LicenseWizard (DatePicker + PredicateView)
+ (NSDate*)systemNowInGMT;
@property (nonatomic, readonly) double secondsSinceMidnight;

// Returns NSDate.date converted from local time zone to GMT.
+ (NSDate*)nowIgnoringTimeZone;

// Returns the intersection interval between the two intervals. 
// If the intervals do not intersect, the method returns NO and leaves the input parameters untouched.
+ (BOOL)clipIntervalBetweenDate:(NSDate**)inOutStartDate 
                        andDate:(NSDate**)inOutEndDate
                       fromDate:(NSDate*)clipStartDate
                         toDate:(NSDate*)clipEndDate;

// Transforms the weekday mask and the time from one calendar into another one. This is used
// to determine the weekdays and time in the GMT timezone.
+ (void)transformWeekDayMask:(PWWeekDayMask*)inOutWeekDayMask
                        time:(NSTimeInterval*)inOutTime
                fromCalendar:(NSCalendar*)fromCalendar
                  toCalendar:(NSCalendar*)toCalendar;

// Transforms the given weekday mask by applying the offset. Offset must be
// in the interval [-7,7]
+ (PWWeekDayMask)transformedWeekDayMask:(PWWeekDayMask)weekDayMask
                             withOffset:(NSInteger)offset;

@end


// Returns the earlier of two dates or nil if both are nil. Returns the first date if both are equal.
NS_INLINE NSDate* PWEarlierDate (NSDate* dateA, NSDate* dateB)
{
    if(!dateA)
        return dateB;
    if(!dateB)
        return dateA;
    return [dateA earlierDate:dateB];
}

// Return the later of two dates or nil if both are nil. Returns the first date if both are equal.
NS_INLINE NSDate* PWLaterDate (NSDate* dateA, NSDate* dateB)
{
    if(!dateA)
        return dateB;
    if(!dateB)
        return dateA;
    return [dateA laterDate:dateB];
}

// Returns whether the two date intervals start1-end1 and start2-end2 intersect. 
// Note: The overlapping interval has to be greater than zero.
NS_INLINE BOOL PWIntersectsDateInterval(NSDate* start1, NSDate* end1, NSDate* start2, NSDate* end2)
{
    return start1 && start2 && [end1 compare:start2]==NSOrderedDescending && [end2 compare:start1]==NSOrderedDescending;
}

NS_INLINE BOOL PWIntersectsTimeInterval(PWAbsoluteTime start1, PWAbsoluteTime end1, PWAbsoluteTime start2, PWAbsoluteTime end2)
{
    return (start1 < end2) && (end1 > start2);
}

void PWAddMonths(NSInteger* inOutYear, NSInteger* inOutMonth, NSInteger deltaMonths);
