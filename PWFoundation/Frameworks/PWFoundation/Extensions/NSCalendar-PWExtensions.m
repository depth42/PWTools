//
//  NSCalendar-MEAdditions.m
//  MerlinModel
//
//  Created by Frank Illenberger on 13.10.05.
//
//

#import "NSCalendar-PWExtensions.h"
#import "NSDate-PWExtensions.h"
#import "PWDispatch.h"
#import "NSObject-PWExtensions.h"

@implementation NSCalendar (PWExtensions)

+ (NSCalendar*)sharedCalendar
{
    static NSCalendar *cal;
    PWDispatchOnce(^{
        cal = [NSCalendar currentCalendar];
    });
    return cal;
}

+ (NSCalendar*)systemCalendar
{
    static NSCalendar *systemCal;
    PWDispatchOnce(^{
        systemCal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        systemCal.timeZone = [NSTimeZone systemTimeZone];
    });    
    return systemCal;
}

+ (NSCalendar*)GMTCalendar
{
    static NSCalendar* cal;
    PWDispatchOnce(^{ 
        cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        cal.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });
    return cal;
}

- (CFAbsoluteTime)absoluteStartTimeOfCalendarWeek:(NSUInteger)week inYear:(NSUInteger)year
{
    NSInteger anchorDayInJanuary;
    NSInteger day = self.firstWeekday;

    // Make sure the day is in the range 1 - 7, as the results for CFCalendarDecomposeAbsoluteTime are in the same range
    // and we want to compare the two.
    if(day==0)
        day = 7;

    NSAssert(day > 0, nil);
    NSAssert(day < 8, nil);

    if(day==2)                      // If based on monday, use german norm (DIN 1355, ISO 8601:1988 und EN 28601:1992)
        anchorDayInJanuary = 4;     // The week containing January 4th is the first calendar week of the year.
    else
        anchorDayInJanuary = 1;     // Otherwise: The week containing January 1st is the first calendar week.
    
    CFAbsoluteTime result;
    CFCalendarComposeAbsoluteTime ((__bridge CFCalendarRef)self, &result, "yMd", year, 1, anchorDayInJanuary);
    int weekday = -1;       // Has to be int even under 64bit
    while(YES)
    {
        CFCalendarDecomposeAbsoluteTime ((__bridge CFCalendarRef)self, result, "E", &weekday);

        NSAssert(weekday > 0, nil);
        NSAssert(weekday < 8, nil);
        
        if (weekday != day)
            CFCalendarAddComponents((__bridge CFCalendarRef)self, &result, 0, "d", -1); 
        else
            break;
    }
    
    CFCalendarAddComponents((__bridge CFCalendarRef)self, &result, 0, "w", week-1);
    return result;
}

- (NSDate*)startOfCalendarWeek:(NSUInteger)week inYear:(NSUInteger)year
{
    return [NSDate dateWithTimeIntervalSinceReferenceDate:[self absoluteStartTimeOfCalendarWeek:week inYear:year]];
}

- (NSDate*)startOfCalendarWeek:(NSDateComponents*)components
{
    return [self startOfCalendarWeek:components.weekOfYear inYear:components.year];
}

- (PWCalendarWeek) calendarWeekFromAbsoluteTime:(CFAbsoluteTime)absoluteTime
{
    // CFCalendarDecomposeAbsoluteTime documentation requests int as the type of all return values.
    int year;
    CFCalendarDecomposeAbsoluteTime ((__bridge CFCalendarRef)self, absoluteTime, "y", &year);
    
    // TODO: use only one startOfCalendarWeek: in most cases
    year++;
    CFAbsoluteTime startOfFirstWeek = [self absoluteStartTimeOfCalendarWeek:1 inYear:year];
    while(startOfFirstWeek >  absoluteTime)
        startOfFirstWeek = [self absoluteStartTimeOfCalendarWeek:1 inYear:--year];
    
    int days;
    CFCalendarGetComponentDifference((__bridge CFCalendarRef)self, startOfFirstWeek, absoluteTime, 0, "d", &days);
    PWCalendarWeek result;
    result.week = 1+days/7;
    result.year = year;
    return result;
}

- (NSDateComponents*) calendarWeekComponentsFromDate:(NSDate*)date
{
    PWCalendarWeek cw = [self calendarWeekFromAbsoluteTime:date.timeIntervalSinceReferenceDate];
    NSDateComponents* comp = [[NSDateComponents alloc] init];
    comp.weekOfYear = cw.week;
    comp.year = cw.year;
    return comp;    
}

// Normalizes time value via modulo to interval 0.0<=time<SECONDS_PER_DAY
+ (NSTimeInterval)normalizedTime:(NSTimeInterval)time
{
    if(time>=SECONDS_PER_DAY)
        time -= SECONDS_PER_DAY*floor(time/SECONDS_PER_DAY);
    else if(time < 0.0)
        time -= SECONDS_PER_DAY*(ceil(time/SECONDS_PER_DAY)-1.0);
    return time;
}

- (NSDate*)startDateOfDayOfDate:(NSDate*)date
{
    NSDate* result = nil;
    if(date)
        result = [self dateFromComponents:[self components:NSCalendarUnitEra | NSCalendarUnitYear
                                           | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date]];
    return result;
}

- (NSDate*)date:(NSDate*)date inComponentsOfCalendar:(NSCalendar*)calendar
{
    NSParameterAssert(date);
    NSParameterAssert(calendar);
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents* comps = [calendar components:unitFlags fromDate:date];
    return [self dateFromComponents:comps];
}

- (NSTimeInterval)secondsSinceMidnightFromDate:(NSDate*)date
{
    NSParameterAssert(date);
 
    NSDateComponents* dateComponents = [self components:(NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)
                                                   fromDate:date];
    return dateComponents.hour * SECONDS_PER_HOUR + dateComponents.minute * SECONDS_PER_MINUTE + dateComponents.second;
}

- (BOOL)isEqualToCalendar:(NSCalendar*)calendar
{
    NSParameterAssert(!calendar || [calendar isKindOfClass:NSCalendar.class]);

    if(!calendar)
        return NO;

    if(calendar == self)
        return YES;
    
    if(   !PWEqualObjects(self.calendarIdentifier, calendar.calendarIdentifier)
       || !PWEqualObjects(self.locale, calendar.locale)
       || ![self.timeZone isEqualToTimeZone:calendar.timeZone]
       || (self.firstWeekday != calendar.firstWeekday))
        return NO;
    
    return YES;
}

@end
