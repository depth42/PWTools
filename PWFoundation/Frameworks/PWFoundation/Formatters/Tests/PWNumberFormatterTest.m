//
//  PWNumberFormatterTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 10.12.09.
//
//

#import "PWNumberFormatterTest.h"
#import "PWNumberFormatter.h"

@implementation PWNumberFormatterTest

- (void)testPercent
{
    PWNumberFormatter* formatter = [[PWNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterPercentStyle;
    [formatter setLenient:YES];
    XCTAssertEqual([formatter numberFromString:@"0%"].doubleValue,      0.0);
    XCTAssertEqual([formatter numberFromString:@"0"].doubleValue,       0.0);
    XCTAssertEqual([formatter numberFromString:@"10%"].doubleValue,     0.1);
    XCTAssertEqual([formatter numberFromString:@"10"].doubleValue,      0.1);
    XCTAssertEqual([formatter numberFromString:@"200 %"].doubleValue,   2.0);
    XCTAssertEqual([formatter numberFromString:@"200"].doubleValue,     2.0);
}

- (void)testCurrency
{
    PWNumberFormatter* formatter = [[PWNumberFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en-en"];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.currencySymbol = @"$";
    [formatter setLenient:YES];
    XCTAssertEqual([formatter numberFromString:@"$0"].doubleValue,      0.0);
    XCTAssertEqual([formatter numberFromString:@"$10"].doubleValue,     10.0);
    XCTAssertEqual([formatter numberFromString:@"$ 10"].doubleValue,    10.0);
    XCTAssertEqual([formatter numberFromString:@"10"].doubleValue,      10.0);

    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de-de"];
    formatter.currencySymbol = @" €";
    XCTAssertEqual([formatter numberFromString:@"0€"].doubleValue,      0.0);
    XCTAssertEqual([formatter numberFromString:@"10€"].doubleValue,     10.0);
    XCTAssertEqual([formatter numberFromString:@"10 €"].doubleValue,    10.0);
    XCTAssertEqual([formatter numberFromString:@"10"].doubleValue,      10.0);
}
@end
