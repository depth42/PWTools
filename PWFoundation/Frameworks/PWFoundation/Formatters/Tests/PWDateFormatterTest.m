//
//  PWDateFormatterTest.m
//  PWFoundation
//
//  Created by Andreas Känner on 05/14/14.
//
//

#import "PWTestCase.h"
#import "PWISODateFormatter.h"
#import "PWDateFormatter.h"
#import "NSFormatter-PWExtensions.h"

@interface PWDateFormatterTest : PWTestCase
@end

@implementation PWDateFormatterTest

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAutoStyleDetection
{
    PWISODateFormatter* ISODateFormatter = [[PWISODateFormatter alloc] init];
    ISODateFormatter.style = PWISODateOnly;
    NSDate* expectedDate = [ISODateFormatter dateFromString:@"2014-01-05"];
    
    // Prepare the date formatter to be lenient. In this case PWDateFormatter tries to use
    // different date and time styles one after the other in order to return a valid date.
    PWDateFormatter* formatter = [[PWDateFormatter alloc] init];
    formatter.lenient = YES;
    formatter.locale  = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];

    // Short date format:
    NSString* string  = @"1/5/14";
    NSDate* date;
    XCTAssertTrue([formatter getObjectValue:&date forString:string error:nil]);
    XCTAssertEqualObjects(date, expectedDate);

    // Medium date format:
    string = @"Jan 05 2014";
    date   = nil;
    XCTAssertTrue([formatter getObjectValue:&date forString:string error:nil]);
    XCTAssertEqualObjects(date, expectedDate);

    // Long date format:
    string = @"Jan 5 2014";
    date   = nil;
    XCTAssertTrue([formatter getObjectValue:&date forString:string error:nil]);
    XCTAssertEqualObjects(date, expectedDate);

    // Full date format:
    string = @"January 5, 2014";
    date   = nil;
    XCTAssertTrue([formatter getObjectValue:&date forString:string error:nil]);
    XCTAssertEqualObjects(date, expectedDate);

    // Do the same but now with time:
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    comps.year   = 2014;
    comps.month  = 1;
    comps.day    = 5;
    comps.hour   = 8;
    comps.minute = 30;
    comps.second = 0;

    expectedDate = [ISODateFormatter.calendar dateFromComponents:comps];

    // Short date format with short time:
    string = @"1/5/14 08:30 am";
    date   = nil;
    XCTAssertTrue([formatter getObjectValue:&date forString:string error:nil]);
    XCTAssertEqualObjects(date, expectedDate);

    // Medium date format with short time:
    string = @"Jan 05 2014 08:30 am";
    date   = nil;
    XCTAssertTrue([formatter getObjectValue:&date forString:string error:nil]);
    XCTAssertEqualObjects(date, expectedDate);

    // Long date format with short time:
    string = @"Jan 5 2014 08:30 am";
    date   = nil;
    XCTAssertTrue([formatter getObjectValue:&date forString:string error:nil]);
    XCTAssertEqualObjects(date, expectedDate);

    // Full date format with short time:
    string = @"January 5, 2014 08:30 am";
    date   = nil;
    XCTAssertTrue([formatter getObjectValue:&date forString:string error:nil]);
    XCTAssertEqualObjects(date, expectedDate);

}

@end
