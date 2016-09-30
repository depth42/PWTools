//
//  NSDate-PWExtensionsTest.m
//  PWFoundation
//
//  Created by Kai Brüning on 29.4.10.
//
//

#import "NSDate-PWExtensionsTest.h"

#import "NSDate-PWExtensions.h"
#import "NSDate-PWTestExtensions.h"

#import "NSCalendar-PWExtensions.h"

@implementation NSDate_PWExtensionsTest

- (void) testForcedNow
{
    NSDate* now = [NSDate date];
    NSDate* forcedDate1 = [NSDate dateWithISOString:@"2010-4-29T12:00:00"];
    NSDate* forcedDate2 = [NSDate dateWithISOString:@"2050-4-29T12:00:00"];
    XCTAssertFalse ([now isEqual:forcedDate1]);
    XCTAssertFalse ([now isEqual:forcedDate2]);
    
    [NSDate setForcedNowToDate:forcedDate1];
    XCTAssertEqualObjects ([NSDate date], forcedDate1);
    
    // Change the forced date without intermediate reset.
    [NSDate setForcedNowToDate:forcedDate2];
    XCTAssertEqualObjects ([NSDate date], forcedDate2);
    
    // Back to normal.
    [NSDate setForcedNowToDate:nil];
    // 30 seconds should be enough even under the most extreme circumstances.
    XCTAssertTrue ([[NSDate date] timeIntervalSinceDate:now] < 30.0);
    
    // Try to force again.
    [NSDate setForcedNowToDate:forcedDate1];
    XCTAssertEqualObjects ([NSDate date], forcedDate1);
    
    // And back
    [NSDate setForcedNowToDate:nil];
    XCTAssertTrue ([[NSDate date] timeIntervalSinceDate:now] < 30.0);
}

- (void) testPWEarlierLaterDate
{
    NSDate* date1 = [NSDate dateWithTimeIntervalSinceReferenceDate:10.0];
    NSDate* date2 = [NSDate dateWithTimeIntervalSinceReferenceDate:10.0];
    NSDate* date3 = [NSDate dateWithTimeIntervalSinceReferenceDate:11.0];
    
    XCTAssertEqual (PWEarlierDate (nil,   nil),   (NSDate*)nil);
    XCTAssertEqual (PWEarlierDate (date1, nil),   date1);
    XCTAssertEqual (PWEarlierDate (nil,   date1), date1);
    XCTAssertEqual (PWEarlierDate (date1, date1), date1);
    XCTAssertEqual (PWEarlierDate (date1, date2), date1);  // note: result could be date2, depends on -earlierDate: impl.
    XCTAssertEqual (PWEarlierDate (date2, date1), date2);  // note: result could be date2, depends on -earlierDate: impl.
    XCTAssertEqual (PWEarlierDate (date1, date3), date1);
    XCTAssertEqual (PWEarlierDate (date3, date1), date1);
    
    XCTAssertEqual (PWLaterDate (nil,   nil),   (NSDate*)nil);
    XCTAssertEqual (PWLaterDate (date1, nil),   date1);
    XCTAssertEqual (PWLaterDate (nil,   date1), date1);
    XCTAssertEqual (PWLaterDate (date1, date1), date1);
    XCTAssertEqual (PWLaterDate (date1, date2), date1);  // note: result could be date2, depends on -laterDate: impl.
    XCTAssertEqual (PWLaterDate (date2, date1), date2);  // note: result could be date2, depends on -laterDate: impl.
    XCTAssertEqual (PWLaterDate (date1, date3), date3);
    XCTAssertEqual (PWLaterDate (date3, date1), date3);
}

- (void)testTransformWeekDayMaskTimeFromCalendarToCalendar
{
    NSCalendar* gmtCalendar = [NSCalendar GMTCalendar];
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    PWWeekDayMask weekDayMask;
    NSTimeInterval time;
    
    //
    // GMT-11:00
    //
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(-11 * SECONDS_PER_HOUR)];
    
    // Monday, 08:00 GMT-11:00 -> Monday, 19:00 GMT
    weekDayMask = PWMondayMask | PWWednesdayMask | PWFridayMask;
    time = 8 * SECONDS_PER_HOUR;
    
    [NSDate transformWeekDayMask:&weekDayMask
                            time:&time
                    fromCalendar:calendar
                      toCalendar:gmtCalendar];
    
    XCTAssertEqual(time, 19 * SECONDS_PER_HOUR);
    XCTAssertEqual(weekDayMask, (PWMondayMask | PWWednesdayMask | PWFridayMask));
    
    // Monday, 15:00 GMT-11:00 -> Tuesday, 02:00 GMT
    weekDayMask = PWMondayMask | PWWednesdayMask | PWFridayMask;
    time = 15 * SECONDS_PER_HOUR;
    
    [NSDate transformWeekDayMask:&weekDayMask
                            time:&time
                    fromCalendar:calendar
                      toCalendar:gmtCalendar];
    
    XCTAssertEqual(time, 2 * SECONDS_PER_HOUR);
    XCTAssertEqual(weekDayMask, (PWTuesdayMask | PWThursdayMask | PWSaturdayMask));
    
    // Monday, 23:00 GMT-11:00 -> Tuesday, 10:00 GMT
    weekDayMask = PWMondayMask | PWWednesdayMask | PWFridayMask;
    time = 23 * SECONDS_PER_HOUR;
    
    [NSDate transformWeekDayMask:&weekDayMask
                            time:&time
                    fromCalendar:calendar
                      toCalendar:gmtCalendar];
    
    XCTAssertEqual(time, 10 * SECONDS_PER_HOUR);
    XCTAssertEqual(weekDayMask, (PWTuesdayMask | PWThursdayMask | PWSaturdayMask));
    
    //
    // GMT+06:00
    //
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(6 * SECONDS_PER_HOUR)];
    
    // Monday, 08:00 GMT+06:00 -> Monday, 02:00 GMT
    weekDayMask = PWMondayMask | PWWednesdayMask | PWFridayMask;
    time = 8 * SECONDS_PER_HOUR;
    
    [NSDate transformWeekDayMask:&weekDayMask
                            time:&time
                    fromCalendar:calendar
                      toCalendar:gmtCalendar];
    
    XCTAssertEqual(time, 2 * SECONDS_PER_HOUR);
    XCTAssertEqual(weekDayMask, (PWMondayMask | PWWednesdayMask | PWFridayMask));
    
    // Monday, 15:00 GMT+06:00 -> Tuesday, 09:00 GMT
    weekDayMask = PWMondayMask | PWWednesdayMask | PWFridayMask;
    time = 15 * SECONDS_PER_HOUR;
    
    [NSDate transformWeekDayMask:&weekDayMask
                            time:&time
                    fromCalendar:calendar
                      toCalendar:gmtCalendar];
    
    XCTAssertEqual(time, 9 * SECONDS_PER_HOUR);
    XCTAssertEqual(weekDayMask, (PWMondayMask | PWWednesdayMask | PWFridayMask));
    
    // Monday, 23:00 GMT+06:00 -> Tuesday, 17:00 GMT
    weekDayMask = PWMondayMask | PWWednesdayMask | PWFridayMask;
    time = 23 * SECONDS_PER_HOUR;
    
    [NSDate transformWeekDayMask:&weekDayMask
                            time:&time
                    fromCalendar:calendar
                      toCalendar:gmtCalendar];
    
    XCTAssertEqual(time, 17 * SECONDS_PER_HOUR);
    XCTAssertEqual(weekDayMask, (PWMondayMask | PWWednesdayMask | PWFridayMask));
    
    //
    // GMT+09:00
    //
    calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:(9 * SECONDS_PER_HOUR)];
    
    // Monday, 08:00 GMT+09:00 -> Sunday, 23:00 GMT
    weekDayMask = PWMondayMask | PWWednesdayMask | PWFridayMask;
    time = 8 * SECONDS_PER_HOUR;
    
    [NSDate transformWeekDayMask:&weekDayMask
                            time:&time
                    fromCalendar:calendar
                      toCalendar:gmtCalendar];
    
    XCTAssertEqual(time, 23 * SECONDS_PER_HOUR);
    XCTAssertEqual(weekDayMask, (PWTuesdayMask | PWThursdayMask | PWSundayMask));
    
    // Monday, 15:00 GMT+09:00 -> Monday, 06:00 GMT
    weekDayMask = PWMondayMask | PWWednesdayMask | PWFridayMask;
    time = 15 * SECONDS_PER_HOUR;
    
    [NSDate transformWeekDayMask:&weekDayMask
                            time:&time
                    fromCalendar:calendar
                      toCalendar:gmtCalendar];
    
    XCTAssertEqual(time, 6 * SECONDS_PER_HOUR);
    XCTAssertEqual(weekDayMask, (PWMondayMask | PWWednesdayMask | PWFridayMask));
    
    // Monday, 23:00 GMT+09:00 -> Monday, 14:00 GMT
    weekDayMask = PWMondayMask | PWWednesdayMask | PWFridayMask;
    time = 23 * SECONDS_PER_HOUR;
    
    [NSDate transformWeekDayMask:&weekDayMask
                            time:&time
                    fromCalendar:calendar
                      toCalendar:gmtCalendar];
    
    XCTAssertEqual(time, 14 * SECONDS_PER_HOUR);
    XCTAssertEqual(weekDayMask, (PWMondayMask | PWWednesdayMask | PWFridayMask));
}

- (void)testTransformedWeekDayMaskWithOffset
{
    PWWeekDayMask transformedWeekDayMask;
    
    PWWeekDayMask weekDayMask = PWMondayMask | PWWednesdayMask | PWFridayMask;
    
    transformedWeekDayMask = [NSDate transformedWeekDayMask:weekDayMask withOffset:0];
    XCTAssertEqual(transformedWeekDayMask, (PWMondayMask | PWWednesdayMask | PWFridayMask));
    
    transformedWeekDayMask = [NSDate transformedWeekDayMask:weekDayMask withOffset:1];
    XCTAssertEqual(transformedWeekDayMask, (PWTuesdayMask | PWThursdayMask | PWSaturdayMask));
    
    transformedWeekDayMask = [NSDate transformedWeekDayMask:weekDayMask withOffset:3];
    XCTAssertEqual(transformedWeekDayMask, (PWThursdayMask | PWSaturdayMask | PWMondayMask));
    
    transformedWeekDayMask = [NSDate transformedWeekDayMask:weekDayMask withOffset:-1];
    XCTAssertEqual(transformedWeekDayMask, (PWTuesdayMask | PWThursdayMask | PWSundayMask));
    
    transformedWeekDayMask = [NSDate transformedWeekDayMask:weekDayMask withOffset:-3];
    XCTAssertEqual(transformedWeekDayMask, (PWFridayMask | PWSundayMask | PWTuesdayMask));
}

@end
