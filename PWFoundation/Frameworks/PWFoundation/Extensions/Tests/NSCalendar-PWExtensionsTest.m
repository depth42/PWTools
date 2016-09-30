//
//  NSCalendar-PWExtensionsTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 08.03.10.
//
//

#import "NSCalendar-PWExtensionsTest.h"
#import "NSCalendar-PWExtensions.h"
#import "NSDate-PWTestExtensions.h"

@implementation NSCalendar_PWExtensionsTest

- (void)testNormalizeTime
{
    XCTAssertEqual([NSCalendar normalizedTime:0.0],  0.0);
    XCTAssertEqual([NSCalendar normalizedTime: 24.0*SECONDS_PER_HOUR], 0.0);
    XCTAssertEqual([NSCalendar normalizedTime:  5.5*SECONDS_PER_HOUR], 5.5*SECONDS_PER_HOUR);
    XCTAssertEqual([NSCalendar normalizedTime: 25.5*SECONDS_PER_HOUR], 1.5*SECONDS_PER_HOUR);
    XCTAssertEqual([NSCalendar normalizedTime: 50.0*SECONDS_PER_HOUR], 2.0*SECONDS_PER_HOUR);
    XCTAssertEqual([NSCalendar normalizedTime: -1.5*SECONDS_PER_HOUR],22.5*SECONDS_PER_HOUR);
    XCTAssertEqual([NSCalendar normalizedTime:-26.0*SECONDS_PER_HOUR],22.0*SECONDS_PER_HOUR);
    XCTAssertEqual([NSCalendar normalizedTime:-51.5*SECONDS_PER_HOUR],20.5*SECONDS_PER_HOUR);
}

- (void)testCalendarWeeksGerman
{
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    cal.firstWeekday = 2;   // monday, german standard
    
    NSDateComponents* comps;
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-01T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)18);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-07T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)18);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-08T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)19);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-14T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)19);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2005-12-26T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2005);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)52);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2005-12-31T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2005);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)52);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-01-01T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2005);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)52);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-01-02T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-12-31T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)52);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2007-01-01T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2007);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2008-12-29T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2009);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2008-12-29T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2009);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2009-01-04T12:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2009);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);
}   

- (void)testStartOfCalendarWeekGerman
{
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal.firstWeekday = 2;   // monday, german standard
    
    XCTAssertEqualObjects([cal startOfCalendarWeek:18 inYear:2006], [NSDate dateWithISOString:@"2006-05-01T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:19 inYear:2006], [NSDate dateWithISOString:@"2006-05-08T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:52 inYear:2005], [NSDate dateWithISOString:@"2005-12-26T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:1  inYear:2006], [NSDate dateWithISOString:@"2006-01-02T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:2  inYear:2006], [NSDate dateWithISOString:@"2006-01-09T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:52 inYear:2006], [NSDate dateWithISOString:@"2006-12-25T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:1  inYear:2007], [NSDate dateWithISOString:@"2007-01-01T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:1  inYear:2009], [NSDate dateWithISOString:@"2008-12-29T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:2  inYear:2009], [NSDate dateWithISOString:@"2009-01-05T00:00:00"]);
}

- (void)testCalendarWeeksEnglish
{
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal.firstWeekday = 1;   // sunday, american standard
    
    NSDateComponents* comps;
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-01T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)18);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-06T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)18);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-07T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)19);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-13T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)19);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2005-12-25T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2005);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)53);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2005-12-31T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2005);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)53);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-01-01T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-12-30T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)52);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-12-31T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2007);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2007-01-01T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2007);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);

    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2007-01-07T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2007);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)2);
}   

- (void)testStartOfCalendarWeekEnglish
{
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal.firstWeekday = 1;   // sunday, american standard
    
    XCTAssertEqualObjects([cal startOfCalendarWeek:18 inYear:2006], [NSDate dateWithISOString:@"2006-04-30T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:19 inYear:2006], [NSDate dateWithISOString:@"2006-05-07T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:52 inYear:2005], [NSDate dateWithISOString:@"2005-12-18T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:1  inYear:2006], [NSDate dateWithISOString:@"2006-01-01T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:2  inYear:2006], [NSDate dateWithISOString:@"2006-01-08T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:52 inYear:2006], [NSDate dateWithISOString:@"2006-12-24T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:1  inYear:2007], [NSDate dateWithISOString:@"2006-12-31T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:1  inYear:2009], [NSDate dateWithISOString:@"2008-12-28T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:2  inYear:2009], [NSDate dateWithISOString:@"2009-01-04T00:00:00"]);
}

- (void)testCalendarWeeksStartingSaturday
{
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal.firstWeekday = 0;   // saturday, used to cause an infinite loop in the computation
    
    NSDateComponents* comps;
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-04-29T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)18);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-05T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)18);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-06T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)19);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-05-12T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)19);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2005-12-24T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2005);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)52);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2005-12-30T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2005);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)52);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2005-12-31T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2006);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2006-12-30T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2007);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2007-01-05T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2007);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2007-01-01T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2007);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)1);
    
    comps = [cal calendarWeekComponentsFromDate:[NSDate dateWithISOString:@"2007-01-08T00:00:00"]];
    XCTAssertEqual(comps.year, (NSInteger)2007);
    XCTAssertEqual(comps.weekOfYear, (NSInteger)2);
}   

- (void)testStartOfCalendarWeekAtSaturday
{
    NSCalendar* cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal.firstWeekday = 0;   // saturday, used to cause an infinite loop in the computation
    
    XCTAssertEqualObjects([cal startOfCalendarWeek:18 inYear:2006], [NSDate dateWithISOString:@"2006-04-29T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:19 inYear:2006], [NSDate dateWithISOString:@"2006-05-06T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:52 inYear:2005], [NSDate dateWithISOString:@"2005-12-24T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:1  inYear:2006], [NSDate dateWithISOString:@"2005-12-31T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:2  inYear:2006], [NSDate dateWithISOString:@"2006-01-07T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:52 inYear:2006], [NSDate dateWithISOString:@"2006-12-23T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:1  inYear:2007], [NSDate dateWithISOString:@"2006-12-30T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:1  inYear:2009], [NSDate dateWithISOString:@"2008-12-27T00:00:00"]);
    XCTAssertEqualObjects([cal startOfCalendarWeek:2  inYear:2009], [NSDate dateWithISOString:@"2009-01-03T00:00:00"]);
}

- (void)testEquality
{
    NSCalendar* cal1 = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal1.firstWeekday = 1;

    NSCalendar* cal2 = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal2.firstWeekday = 1;

    NSCalendar* cal3 = [cal1 copy];
    cal3.firstWeekday = 2;

    NSCalendar* cal4 = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    cal4.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:42.0];
    
    XCTAssertTrue([cal1 isEqualToCalendar:cal1]);
    XCTAssertTrue([cal1 isEqualToCalendar:cal2]);
    XCTAssertTrue([cal2 isEqualToCalendar:cal1]);

    XCTAssertFalse([cal1 isEqualToCalendar:cal3]);
    XCTAssertFalse([cal3 isEqualToCalendar:cal1]);

    XCTAssertFalse([cal1 isEqualToCalendar:cal4]);
    XCTAssertFalse([cal4 isEqualToCalendar:cal1]);

    XCTAssertFalse([cal3 isEqualToCalendar:cal4]);
    XCTAssertFalse([cal4 isEqualToCalendar:cal3]);
}

@end
