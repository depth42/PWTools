//
//  PWCurrencyFormatterTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 04.03.10.
//
//

#import "PWCurrencyFormatterTest.h"
#import "PWLocality.h"
#import "PWCurrencyFormatter.h"
#import "NSFormatter-PWExtensions.h"

@implementation PWCurrencyFormatterTest

- (void)testEnglish
{
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];
    PWLocality* locality = [[PWLocality alloc] initWithLocale:locale
                                                     language:@"English"];
    
    PWCurrencyFormatter* formatter = [[PWCurrencyFormatter alloc] initWithLocality:locality hideZeroes:NO];
    XCTAssertEqualObjects([formatter stringFromNumber:@42.0], @"$42.00");
    XCTAssertEqualObjects([formatter stringFromNumber:@0], @"$0.00");
    XCTAssertEqualObjects([formatter stringFromNumber:@-42.0], @"($42.00)");
}

- (void)testEnglishWithCustomCurrency
{
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];
    PWLocality* locality = [[PWLocality alloc] initWithLocale:locale
                                                     language:@"English"
                                               currencySymbol:@"CUR"
                                       currencySymbolPosition:PWUnitAfterAmountWithoutSpace
                                                     calendar:nil];
    
    PWCurrencyFormatter* formatter = [[PWCurrencyFormatter alloc] initWithLocality:locality hideZeroes:YES];
    XCTAssertEqualObjects([formatter stringFromNumber:@42.0], @"42.00CUR");
    XCTAssertEqualObjects([formatter stringFromNumber:@0], @"");
    XCTAssertEqualObjects([formatter stringFromNumber:@-42.0], @"(42.00CUR)");
}

- (void)testGermanWithCustomCurrency
{
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de-DE"];
    PWLocality* locality = [[PWLocality alloc] initWithLocale:locale
                                                     language:@"German"
                                               currencySymbol:@"CUR"
                                       currencySymbolPosition:PWUnitBeforeAmountWithSpace
                                                     calendar:nil];

    PWCurrencyFormatter* formatter = [[PWCurrencyFormatter alloc] initWithLocality:locality hideZeroes:NO];
    XCTAssertEqualObjects([formatter stringFromNumber:@42.0], @"CUR 42,00");
    XCTAssertEqualObjects([formatter stringFromNumber:@0], @"CUR 0,00");
    XCTAssertEqualObjects([formatter stringFromNumber:@-42.0], @"-CUR 42,00");
}

- (void)testMoreLocales
{
    [self checkLocale:@"fr_NE"      stringA:@"CUR 12 345 678"       stringB:@"12 345 678CUR"        stringC:@"(CUR 12 345 678)"     stringD:@"(12 345 678CUR)"];
    [self checkLocale:@"pa_Guru"    stringA:@"CUR 1,23,45,678.12"   stringB:@"1,23,45,678.12CUR"    stringC:@"-CUR 1,23,45,678.12"  stringD:@"-1,23,45,678.12CUR"];
}

- (void)checkLocale:(NSString*)localeID
            stringA:(NSString*)stringA
            stringB:(NSString*)stringB
            stringC:(NSString*)stringC
            stringD:(NSString*)stringD
{
    NSParameterAssert(localeID);
    NSParameterAssert(stringA);
    NSParameterAssert(stringB);

    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:localeID];
    PWLocality* localityA = [[PWLocality alloc] initWithLocale:locale
                                                      language:@"English"
                                                currencySymbol:@"CUR"
                                        currencySymbolPosition:PWUnitBeforeAmountWithSpace
                                                      calendar:nil];
    PWLocality* localityB = [[PWLocality alloc] initWithLocale:locale
                                                      language:@"English"
                                                currencySymbol:@"CUR"
                                        currencySymbolPosition:PWUnitAfterAmountWithoutSpace
                                                      calendar:nil];

    PWCurrencyFormatter* formatterA = [[PWCurrencyFormatter alloc] initWithLocality:localityA hideZeroes:NO];
    PWCurrencyFormatter* formatterB = [[PWCurrencyFormatter alloc] initWithLocality:localityB hideZeroes:NO];

    NSNumber* number = @12345678.123456;
    NSNumber* negativeNumber = @(-number.doubleValue);
    XCTAssertEqualObjects([formatterA stringFromNumber:number], stringA);
    XCTAssertEqualObjects([formatterB stringFromNumber:number], stringB);
    XCTAssertEqualObjects([formatterA stringFromNumber:negativeNumber], stringC);
    XCTAssertEqualObjects([formatterB stringFromNumber:negativeNumber], stringD);
}

+ (BOOL)isYosemiteOrLater
{
    return rint(NSFoundationVersionNumber) > 1056 /* NSFoundationVersionNumber10_9 */;
}

- (void)testNegativeFormatBug
{
    // Starting with iOS 8 and OS X 10.10, the default number format for negative currency values in the en_US locale seems to have changed from ($42.42) to -$42.42.
    // We regard this as a bug and reported it in rdar://18718954
    // We work around this in PWCurrencyFormatter.
    // This test fails once Apple has fixed this bug.
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];
    NSNumberFormatter* formatter = [NSNumberFormatter new];
    formatter.locale = locale;
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;

#if UXTARGET_IOS9
    XCTAssertEqualObjects(formatter.negativeFormat, @"¤#,##0.00", @"Yeah! Apple fixed the negative currency formatter bug!");
#else
    if(self.class.isYosemiteOrLater)
        XCTAssertEqualObjects(formatter.negativeFormat, @"¤#,##0.00", @"Yeah! Apple fixed the negative currency formatter bug!");
    else
        XCTAssertEqualObjects(formatter.negativeFormat, @"(¤#,##0.00)");
#endif
}

- (void)testWhitespaceStringBug
{
    // NSNumberFormatter crashes when the zero symbol is an empty string or one that only contains whitespace (we use
    // this behavior when creating a currency formatter that hides zeros) and the string to be converted consists of
    // only whitespace.
    // We regard this as a bug and reported it in rdar://26517712
    // We work around this in PWCurrencyFormatter.
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de-DE"];
    PWLocality* locality = [[PWLocality alloc] initWithLocale:locale
                                                     language:@"German"
                                               currencySymbol:@"€"
                                       currencySymbolPosition:PWUnitBeforeAmountWithSpace
                                                     calendar:nil];
    
    PWCurrencyFormatter* formatter = [[PWCurrencyFormatter alloc] initWithLocality:locality hideZeroes:YES];
    
    NSError* error;
    NSNumber* number;
    XCTAssertTrue([formatter getObjectValue:&number forString:@" " error:&error], @"%@", error);
    XCTAssertNil(number);
}

- (void)testNorwegianWithCustomCurrencyBeforeAmount
{
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"nb_US"];
    PWLocality* locality = [[PWLocality alloc] initWithLocale:locale
                                                     language:@"Norwegian"
                                               currencySymbol:@"kr"
                                       currencySymbolPosition:PWUnitBeforeAmountWithoutSpace
                                                     calendar:nil];

    PWCurrencyFormatter* formatter = [[PWCurrencyFormatter alloc] initWithLocality:locality hideZeroes:YES];

    XCTAssertEqualObjects([formatter stringFromNumber:@42.0], @"kr42,00");
    XCTAssertEqualObjects([formatter stringFromNumber:@0], @"");
    XCTAssertEqualObjects([formatter stringFromNumber:@-42.0], @"−kr42,00");

    NSError* error;
    NSNumber* number;

    XCTAssertTrue([formatter getObjectValue:&number forString:@"-kr100,12" error:&error], @"%@", error);
    XCTAssertEqualObjects(number, @-100.12);

    // With special minus character (U+2212)
    XCTAssertTrue([formatter getObjectValue:&number forString:@"−100" error:&error], @"%@", error);
    XCTAssertEqualObjects(number, @-100);

    // With regular minus character
    XCTAssertTrue([formatter getObjectValue:&number forString:@"-100" error:&error], @"%@", error);
    XCTAssertEqualObjects(number, @-100);
}

- (void)testEnglishWithCustomCurrencyBeforeAmount
{
    NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];
    PWLocality* locality = [[PWLocality alloc] initWithLocale:locale
                                                     language:@"English"
                                               currencySymbol:@"CUR"
                                       currencySymbolPosition:PWUnitBeforeAmountWithoutSpace
                                                     calendar:nil];

    PWCurrencyFormatter* formatter = [[PWCurrencyFormatter alloc] initWithLocality:locality hideZeroes:YES];

    XCTAssertEqualObjects([formatter stringFromNumber:@42.0], @"CUR42.00");
    XCTAssertEqualObjects([formatter stringFromNumber:@0], @"");
    XCTAssertEqualObjects([formatter stringFromNumber:@-42.0], @"(CUR42.00)");

    NSError* error;
    NSNumber* number;

    XCTAssertTrue([formatter getObjectValue:&number forString:@"(CUR100.12)" error:&error], @"%@", error);
    XCTAssertEqualObjects(number, @-100.12);

    XCTAssertTrue([formatter getObjectValue:&number forString:@"-100.15" error:&error], @"%@", error);
    XCTAssertEqualObjects(number, @-100.15);

    XCTAssertTrue([formatter getObjectValue:&number forString:@"-CUR100.16" error:&error], @"%@", error);
    XCTAssertEqualObjects(number, @-100.16);
}

@end
