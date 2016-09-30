//
//  NSDate-PWExtensions.m
//  Merlin
//
//  Created by Frank Illenberger on 30.07.05.
//
//

#import "NSDate-PWExtensions.h"
#import "NSObject-PWExtensions.h"
#import "NSCalendar-PWExtensions.h"
#import "PWDispatch.h"
#import "PWISODateFormatter.h"
#import "NSFormatter-PWExtensions.h"
#import "NSCalendar-PWExtensions.h"
#import <objc/runtime.h>

static NSString* const PWForcedDateKey = @"PWForcedDate";

@implementation NSDate (PWExtensions)

+ (NSDate*) forcedDate
{
    return [self associatedObjectForKey:PWForcedDateKey];
}

+ (void) setForcedNowToDate:(NSDate*)forcedDate
{
    NSDate* oldForcedDate = [self associatedObjectForKey:PWForcedDateKey];
    // Exchange method implementation when going from unforced to forced or vice versa.
    if ((forcedDate != nil) != (oldForcedDate != nil)) {
        Method original = class_getClassMethod (self, @selector (date));
        Method patched  = class_getClassMethod (self, @selector (forcedDate));
        NSAssert (original != NULL && patched != NULL, nil);
        method_exchangeImplementations (original, patched);
    }
    [self setAssociatedObject:forcedDate forKey:PWForcedDateKey copy:YES];
}

- (NSDate*)systemDateInGMT
{
    NSUInteger unitFlags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSDateComponents *comps = [[NSCalendar currentCalendar] components:unitFlags fromDate:self];
    return [[NSCalendar GMTCalendar] dateFromComponents:comps];
}

+ (NSDate*)systemNowInGMT
{
    return [[NSDate date] systemDateInGMT];
}

+ (void)setSystemNowInGMTToDate:(NSDate*)forcedDate
{
    NSTimeZone* sysZone = [NSCalendar currentCalendar].timeZone;
    NSDate* date = [forcedDate dateByAddingTimeInterval:-[sysZone secondsFromGMTForDate:forcedDate]];
    [self setForcedNowToDate:date];
}

+ (NSDate*)nowIgnoringTimeZone
{
    NSDate* now = NSDate.date;
    
    NSInteger offset = [NSTimeZone.localTimeZone secondsFromGMTForDate:now];
    return [NSDate dateWithTimeIntervalSinceReferenceDate:now.timeIntervalSinceReferenceDate + offset];
}

- (NSDate*) dateByRoundingToSeconds
{
    NSTimeInterval interval = self.timeIntervalSinceReferenceDate;
    NSTimeInterval roundedInterval = floor (interval + 0.5);
    return (roundedInterval == interval) ? self : [NSDate dateWithTimeIntervalSinceReferenceDate:roundedInterval];
}

- (double)secondsSinceMidnight
{
    double ref = self.timeIntervalSinceReferenceDate;
    double day = (NSInteger)(ref/86400.0);
    return ref - day*86400.0;
}

void PWAddMonths(NSInteger* inOutYear, NSInteger* inOutMonth, NSInteger deltaMonths)
{
    NSCParameterAssert(inOutYear);
    NSCParameterAssert(inOutMonth);
    NSInteger month = *inOutMonth;
    NSInteger year = *inOutYear;
    NSCParameterAssert(month>=1 && month<=12);
    
    month += deltaMonths;
    if(month > 12)
    {
        NSInteger deltaYears = month / 12;
        year += deltaYears;
        month -= deltaYears*12;
    }
    else if(month < 1)
    {
        NSInteger deltaYears = (month / 12) - 1;
        year += deltaYears;
        month -= deltaYears*12;
        
    }
    *inOutMonth = month;
    *inOutYear  = year;
}

// Override from NSObject-PWExtensions
- (BOOL)isEqualFuzzy:(id)obj
{
    if(![obj isKindOfClass:NSDate.class])
        return NO;
    return PWEqualDoubles(self.timeIntervalSinceReferenceDate, ((NSDate*)obj).timeIntervalSinceReferenceDate);
}

+ (BOOL)clipIntervalBetweenDate:(NSDate**)inOutStartDate 
                        andDate:(NSDate**)inOutEndDate
                       fromDate:(NSDate*)clipStartDate
                         toDate:(NSDate*)clipEndDate
{
    NSParameterAssert(inOutStartDate);
    NSParameterAssert(inOutEndDate);
    
    if(!clipStartDate || !clipEndDate)
        return YES;
    NSDate* startDate = [clipStartDate   laterDate:*inOutStartDate];
    NSDate* endDate   = [clipEndDate   earlierDate:*inOutEndDate];
    if([startDate compare:endDate]==NSOrderedAscending)
    {
        *inOutStartDate = startDate;
        *inOutEndDate   = endDate;
        return YES;
    }
    else
        return NO;
}

#pragma mark - Weekdays and time transformation

+ (void)transformWeekDayMask:(PWWeekDayMask*)inOutWeekDayMask
                        time:(NSTimeInterval*)inOutTime
                fromCalendar:(NSCalendar*)fromCalendar
                  toCalendar:(NSCalendar*)toCalendar
{
    NSParameterAssert(inOutWeekDayMask);
    NSParameterAssert(inOutTime);
    NSParameterAssert(fromCalendar);
    NSParameterAssert(toCalendar);
    
    NSUInteger components = (NSCalendarUnitWeekday | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute);
    
    // Set date components to a reference date with the time that should be transformed
    NSDateComponents* dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2001;
    dateComponents.month = 1;
    dateComponents.day = 1;
    dateComponents.weekday = 2;
    dateComponents.hour = *inOutTime / SECONDS_PER_HOUR;
    dateComponents.minute = (*inOutTime - dateComponents.hour * SECONDS_PER_HOUR) / SECONDS_PER_MINUTE;
    
    NSInteger fromWeekDay = dateComponents.weekday;
    
    // Create a new date from the modified date components and break this date up into components based on the
    // target NSCalendar
    NSDate* date = [fromCalendar dateFromComponents:dateComponents];
    dateComponents = [toCalendar components:components
                                   fromDate:date];
    NSInteger toWeekDay = dateComponents.weekday;
    
    // Compute the offset for the weekdays between the two calendars
    NSInteger weekDayOffset = toWeekDay - fromWeekDay;
    
    // Transform both the desired weekday mask and the time to the target NSCalendar
    PWWeekDayMask toWeekDayMask = [NSDate transformedWeekDayMask:*inOutWeekDayMask
                                                      withOffset:weekDayOffset];
    NSTimeInterval toTime = dateComponents.hour * SECONDS_PER_HOUR + dateComponents.minute * SECONDS_PER_MINUTE;
    
    // Return the transformed weekdays and time
    *inOutWeekDayMask = toWeekDayMask;
    *inOutTime = toTime;
}

+ (PWWeekDayMask)transformedWeekDayMask:(PWWeekDayMask)weekDayMask
                             withOffset:(NSInteger)offset
{
    NSParameterAssert(offset >= -7 && offset <= 7);
    
    if(offset == 0 || weekDayMask == 0)
        return weekDayMask;
    
    PWWeekDayMask convertedWeekDayMask = 0;
    for(NSUInteger iWeekDay = 0; iWeekDay < 7; iWeekDay++)
        if((weekDayMask & (1 << iWeekDay)) > 0)
            convertedWeekDayMask |= 1 << ((iWeekDay + offset + 7) % 7);
    return convertedWeekDayMask;
}

@end
