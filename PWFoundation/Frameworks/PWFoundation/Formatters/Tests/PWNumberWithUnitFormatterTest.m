//
//  PWNumberWithUnitFormatterTest.m
//  PWFoundation
//
//  Created by Torsten Radtke on 24.03.11.
//
//

#import "PWNumberWithUnitFormatterTest.h"

#import "PWNumberWithUnitFormatter.h"

@implementation PWNumberWithUnitFormatterTest

- (void)testNumberFromString
{
    PWNumberWithUnitFormatter* formatter = [[PWNumberWithUnitFormatter alloc] init];
    [formatter setUnit:@"in" factor:1.0/72.0];
    
    XCTAssertEqual([formatter numberFromString:@"1"].doubleValue,      72.0);
    XCTAssertEqual([formatter numberFromString:@"1in"].doubleValue,    72.0);
    XCTAssertEqual([formatter numberFromString:@"1 in"].doubleValue,   72.0);
    XCTAssertEqual([formatter numberFromString:@"10"].doubleValue,    720.0);
    XCTAssertEqual([formatter numberFromString:@"10in"].doubleValue,  720.0);
    XCTAssertEqual([formatter numberFromString:@"10 in"].doubleValue, 720.0);
}

- (void)testStringFromNumber
{
    PWNumberWithUnitFormatter* formatter = [[PWNumberWithUnitFormatter alloc] init];
    [formatter setUnit:@"in" factor:1.0/72.0];
    
    XCTAssertEqualObjects([formatter stringFromNumber:@72.0], @"1 in");
    XCTAssertEqualObjects([formatter stringFromNumber:@144.0], @"2 in");
}

- (void)testStringForObjectValue
{
    PWNumberWithUnitFormatter* formatter = [[PWNumberWithUnitFormatter alloc] init];
    [formatter setUnit:@"in" factor:1.0/72.0];

    XCTAssertEqualObjects([formatter stringForObjectValue:@144.0], @"2 in");

    // Special cases for empty string and nil
    XCTAssertEqualObjects([formatter stringForObjectValue:@""], @"");

    // Starting with iOS9/OS X 10.11 SDK, passing nil to stringForObjectValue: creates a compiler warning.
    // We regard this as an error in the SDK and filed a radar on it. In the meantime, we silence the warning.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertEqualObjects([formatter stringForObjectValue:nil], @"");
#pragma clang diagnostic pop
}

@end
