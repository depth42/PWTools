//
//  NSDate-PWTestExtensions.m
//  MerlinModel
//
//  Created by Kai on 11.3.10.
//
//

#import "NSDate-PWTestExtensions.h"
#import <PWFoundation/PWISODateFormatter.h>
#import <PWFoundation/PWDispatch.h>
#import <PWFoundation/NSCalendar-PWExtensions.h>

@implementation NSDate (PWTestExtensions)

+ (NSDate*) dateWithISOString:(NSString*)dateString
{
    static PWISODateFormatter* formatter;
    PWDispatchOnce (^ {
        // Use gregorian calendar with default time zone.
        // Note: MerlinModel overwrites this method to force gmt time zone.
        NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
        
        formatter = [[PWISODateFormatter alloc] init];
        formatter.calendar = calendar;
        formatter.style = PWISODateAndTime;
    });

    NSDate* date = [formatter dateFromString:dateString];
    NSAssert1 (date, @"invalid ISO date string “%@”", dateString);
    return date;
}

+ (NSDate*) dateWithISOString:(NSString*)dateString timeZone:(NSTimeZone*)timeZone
{
    NSParameterAssert (dateString);
    NSParameterAssert (timeZone);

    NSDate* gmtDate = [self GMTDateWithISOString:dateString];
    return [gmtDate dateByAddingTimeInterval:-[timeZone secondsFromGMTForDate:gmtDate]];
}

+ (NSDate*) GMTDateWithISOString:(NSString*)dateString
{
    static PWISODateFormatter* formatter;
    PWDispatchOnce (^ {
        formatter = [[PWISODateFormatter alloc] init];
        formatter.calendar = [NSCalendar GMTCalendar];
        formatter.style = PWISODateAndTime;
    });
    NSDate* date = [formatter dateFromString:dateString];
    NSAssert1 (date, @"invalid ISO date string “%@”", dateString);
    return date;
}

@end
