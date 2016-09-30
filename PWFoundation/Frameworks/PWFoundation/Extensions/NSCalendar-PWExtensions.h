//
//  NSCalendar-MEAdditions.h
//  MerlinModel
//
//  Created by Frank Illenberger on 13.10.05.
//
//

#import <Foundation/Foundation.h>
#import <PWFoundation/PWSDKAvailability.h>

#define SECONDS_PER_HOUR 3600.0
#define SECONDS_PER_DAY 86400.0
#define SECONDS_PER_WEEK 604800.0
#define MINUTES_PER_HOUR 60.0
#define SECONDS_PER_MINUTE 60.0

typedef struct PWCalendarWeek
{
    unsigned int year;
    unsigned int week; 
} PWCalendarWeek;

@interface NSCalendar (PWExtensions)

+ (NSCalendar*)sharedCalendar;
+ (NSCalendar*)systemCalendar;
+ (NSCalendar*)GMTCalendar;
- (NSDateComponents*)calendarWeekComponentsFromDate:(NSDate*)date;
- (NSDate*)startOfCalendarWeek:(NSDateComponents*)components;
- (NSDate*)startOfCalendarWeek:(NSUInteger)week inYear:(NSUInteger)year;

+ (NSTimeInterval)normalizedTime:(NSTimeInterval)time;
- (NSDate*)startDateOfDayOfDate:(NSDate*)date;

// Takes the components of the given date in the specified calendar and then 
// creates a new date with these components within the receiving calendar.
- (NSDate*)date:(NSDate*)date inComponentsOfCalendar:(NSCalendar*)calendar;

- (NSTimeInterval)secondsSinceMidnightFromDate:(NSDate*)date;

// Checks not only for equality of the calendarIdentifier (like isEqual:) but takes
// firstWeekday and timeZone into account.
- (BOOL)isEqualToCalendar:(NSCalendar*)calendar;

@end
