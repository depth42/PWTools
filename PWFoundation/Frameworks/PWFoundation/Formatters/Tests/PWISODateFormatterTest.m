//
//  PWISODateFormatterTest.m
//  PWFoundation
//
//  Created by Kai Brüning on 7.5.10.
//
//

#import "PWISODateFormatterTest.h"
#import "PWISODateFormatter.h"
#import "NSDate-PWTestExtensions.h"


@implementation PWISODateFormatterTest

- (void) testParsing
{
    PWISODateFormatter* formatter = [[PWISODateFormatter alloc] init];
    XCTAssertEqual(formatter.style, PWISODateAndTime);
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    comps.year  = 2010;
    comps.month = 5;
    comps.day   = 7;

    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7"],
                          [formatter.calendar dateFromComponents:comps]);

    comps.hour = 8;
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7T8"],
                          [formatter.calendar dateFromComponents:comps]);

    comps.minute = 30;
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7t8:30"],
                          [formatter.calendar dateFromComponents:comps]);

    comps.second = 15;
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7  8:30:15"],
                          [formatter.calendar dateFromComponents:comps]);

    XCTAssertEqual        ([[formatter dateFromString:@"2010-5-7T	8:30:15.25"]
                           timeIntervalSinceDate:[formatter.calendar dateFromComponents:comps]], 0.25);
    
    XCTAssertNil          ([formatter dateFromString:nil]);
    XCTAssertNil          ([formatter dateFromString:@""]);
}

- (void)testParsingDateOnly
{
    PWISODateFormatter* formatter = [[PWISODateFormatter alloc] init];
    formatter.style = PWISODateOnly;
    
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    comps.year  = 2010;
    comps.month = 5;
    comps.day   = 7;
    
    NSDate* date = [formatter.calendar dateFromComponents:comps];
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7"],                   date);
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7T8"],                 date);
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7t8:30"],              date);
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7  8:30:15"],          date);
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7 	8:30:15.25"],    date);
}

- (void) testParsingWithSecondFraction
{
    PWISODateFormatter* formatter = [[PWISODateFormatter alloc] init];
    // For parsing there’s (so far) no difference between PWISODateAndTime and PWISODateAndTimeWithSecondFraction.
    formatter.style = PWISODateAndTimeWithSecondFraction;
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    comps.year  = 2010;
    comps.month = 5;
    comps.day   = 7;
    
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7"],
                           [formatter.calendar dateFromComponents:comps]);
    
    comps.hour = 8;
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7T8"],
                           [formatter.calendar dateFromComponents:comps]);
    
    comps.minute = 30;
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7t8:30"],
                           [formatter.calendar dateFromComponents:comps]);
    
    comps.second = 15;
    XCTAssertEqualObjects ([formatter dateFromString:@"2010-5-7  8:30:15"],
                           [formatter.calendar dateFromComponents:comps]);
    
    XCTAssertEqual        ([[formatter dateFromString:@"2010-5-7T	8:30:15.25"]
                            timeIntervalSinceDate:[formatter.calendar dateFromComponents:comps]], 0.25);

    XCTAssertEqualWithAccuracy([[formatter dateFromString:@"2010-5-7T	8:30:15.0000025"]
                                timeIntervalSinceDate:[formatter.calendar dateFromComponents:comps]], 0.0000025, 1e-8);

    XCTAssertNil          ([formatter dateFromString:nil]);
    XCTAssertNil          ([formatter dateFromString:@""]);
}

- (void) testFormatting
{
    PWISODateFormatter* formatter = [[PWISODateFormatter alloc] init];
    
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    comps.year  = 2010;
    comps.month = 5;
    comps.day   = 7;
    
    XCTAssertEqualObjects ([formatter stringFromDate:[formatter.calendar dateFromComponents:comps]],
                          @"2010-05-07T00:00:00" );

    comps.month = 11;
    comps.hour = 8;
    XCTAssertEqualObjects ([formatter stringFromDate:[formatter.calendar dateFromComponents:comps]],
                          @"2010-11-07T08:00:00" );

    comps.day = 13;
    comps.hour = 11;
    comps.minute = 15;
    XCTAssertEqualObjects ([formatter stringFromDate:[formatter.calendar dateFromComponents:comps]],
                          @"2010-11-13T11:15:00" );

    comps.second = 59;
    XCTAssertEqualObjects ([formatter stringForObjectValue:[formatter.calendar dateFromComponents:comps]],
                          @"2010-11-13T11:15:59" );

    formatter.style = PWISODateAndTimeWithSecondFraction;
    XCTAssertEqualObjects ([formatter stringForObjectValue:[formatter.calendar dateFromComponents:comps]],
                           @"2010-11-13T11:15:59" );
    
    comps.nanosecond = 500000000;
    formatter.style = PWISODateAndTime;
    XCTAssertEqualObjects ([formatter stringForObjectValue:[formatter.calendar dateFromComponents:comps]],
                           @"2010-11-13T11:15:59" );

    formatter.style = PWISODateAndTimeWithSecondFraction;
    XCTAssertEqualObjects ([formatter stringForObjectValue:[formatter.calendar dateFromComponents:comps]],
                           @"2010-11-13T11:15:59.5" );

    comps.nanosecond = 2500;
    formatter.style = PWISODateAndTimeWithSecondFraction;
    XCTAssertEqualObjects ([formatter stringForObjectValue:[formatter.calendar dateFromComponents:comps]],
                           @"2010-11-13T11:15:59.0000025" );
}

- (void) testFormattingDateOnly
{
    PWISODateFormatter* formatter = [[PWISODateFormatter alloc] init];
    formatter.style = PWISODateOnly;
    
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    comps.year  = 2010;
    comps.month = 5;
    comps.day   = 7;
    
    XCTAssertEqualObjects ([formatter stringFromDate:[formatter.calendar dateFromComponents:comps]],
                          @"2010-05-07" );
    
    comps.month = 11;
    comps.hour = 8;
    XCTAssertEqualObjects ([formatter stringFromDate:[formatter.calendar dateFromComponents:comps]],
                          @"2010-11-07" );
    
    comps.day = 13;
    comps.hour = 11;
    comps.minute = 15;
    XCTAssertEqualObjects ([formatter stringFromDate:[formatter.calendar dateFromComponents:comps]],
                          @"2010-11-13" );
    
    comps.second = 59;
    XCTAssertEqualObjects ([formatter stringForObjectValue:[formatter.calendar dateFromComponents:comps]],
                          @"2010-11-13" );
    
}

- (void) testErrors
{
    PWISODateFormatter* formatter = [[PWISODateFormatter alloc] init];
    
    XCTAssertThrows ([formatter stringForObjectValue:@"no date"]);
}

@end
