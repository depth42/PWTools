//
//  PWISOTimeFormatterTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 23.09.10.
//
//

#import "PWISOTimeFormatterTest.h"
#import "PWISOTimeFormatter.h"
#import "PWTypes.h"

@implementation PWISOTimeFormatterTest

- (void) testParsing
{
    PWISOTimeFormatter* formatter = [[PWISOTimeFormatter alloc] init];
    
    XCTAssertEqualObjects ([formatter timeFromString:@"8:30"],
                          @(8.0*3600.0 + 30.0 * 60.0));
    
    XCTAssertEqualObjects ([formatter timeFromString:@"08:30:45"],
                          @(8.0*3600.0 + 30.0 * 60.0 + 45.0));

    XCTAssertEqualObjects ([formatter timeFromString:@"23:30:45.123"],
                          @(23.0*3600.0 + 30.0 * 60.0 + 45.123));
    
    XCTAssertEqualObjects ([formatter timeFromString:@"24:00:00"],
                          @(24.0*3600.0));

}

- (void) testFormatting
{
    PWISOTimeFormatter* formatter = [[PWISOTimeFormatter alloc] init];
    XCTAssertEqualObjects ([formatter stringFromTime:@(4.0*3600.0)], @"04:00:00" );
    XCTAssertEqualObjects ([formatter stringFromTime:@(8.0*3600.0 + 30.0 * 60.0)], @"08:30:00" );
    XCTAssertEqualObjects ([formatter stringFromTime:@(8.0*3600.0 + 30.0 * 60.0 + 5.0)], @"08:30:05" );
    XCTAssertEqualObjects ([formatter stringFromTime:@(8.0*3600.0 + 30.0 * 60.0 + 45.123)], @"08:30:45.123" );
    XCTAssertEqualObjects ([formatter stringForObjectValue:@(23.0*3600.0 + 30.0 * 60.0 + 45.123)], @"23:30:45.123" );
  
}

- (void) testErrors
{
    PWISOTimeFormatter* formatter = [[PWISOTimeFormatter alloc] init];
    
    XCTAssertThrows ([formatter stringForObjectValue:@"no time"]);
    XCTAssertNil ([formatter timeFromString:@"45:25"]);
    id val = nil;
    XCTAssertFalse ([formatter getObjectValue:&val forString:@"08" errorDescription:NULL]);
    XCTAssertFalse ([formatter getObjectValue:&val forString:@"45:25" errorDescription:NULL]);
    XCTAssertFalse ([formatter getObjectValue:&val forString:@"Hallo" errorDescription:NULL]);
}

@end
