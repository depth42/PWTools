//
//  NSString-PWExtensionsTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 01.04.10.
//
//

#import "NSString-PWExtensionsTest.h"
#import "NSString-PWExtensions.h"
#import "NSData-PWExtensions.h"

@implementation NSString_PWExtensionsTest

- (void)testEncodingDetection
{
#if UXTARGET_IOS
    // PWASSERT_NOT_YET_IMPLEMENTED
#else
    NSString* testString = @"Görgülü est un garçon qui rêve, !=?abcd ABCE !§$%&/()";
    NSData* utf8Data        = [testString dataUsingEncoding:NSUTF8StringEncoding];
    NSData* isoLatin1Data   = [testString dataUsingEncoding:NSISOLatin1StringEncoding];
 
    XCTAssertEqual([NSString bestEncodingOfStringInData:utf8Data],          (NSStringEncoding)NSUTF8StringEncoding);
    XCTAssertEqual([NSString bestEncodingOfStringInData:isoLatin1Data],     (NSStringEncoding)NSISOLatin1StringEncoding);

    XCTAssertEqual([NSString bestEncodingOfStringInData:[NSData data]],     (NSStringEncoding)0);
#endif
}

- (void)testCountOfString
{
    NSString* str = @"one two one one two One x";
    XCTAssertEqual([str countOfString:@"one" options:NSLiteralSearch],         (NSUInteger)3);
    XCTAssertEqual([str countOfString:@"one" options:NSCaseInsensitiveSearch], (NSUInteger)4);
    XCTAssertEqual([str countOfString:@"two" options:NSCaseInsensitiveSearch], (NSUInteger)2);
    XCTAssertEqual([str countOfString:@"x"   options:NSCaseInsensitiveSearch], (NSUInteger)1);
    XCTAssertEqual([str countOfString:@"z"   options:NSCaseInsensitiveSearch], (NSUInteger)0);
}

- (void) testUniquingTitle
{
    XCTAssertEqualObjects ([@"test" stringByUniquingInTitles:nil], @"test");
    XCTAssertEqualObjects ([@"test" stringByUniquingInTitles:([NSSet setWithObjects:@"tester", @"bla", nil])],
                          @"test");
    XCTAssertEqualObjects ([@"test" stringByUniquingInTitles:([NSSet setWithObjects:@"test", @"bla", nil])],
                          @"test 02");
    XCTAssertEqualObjects ([@"test" stringByUniquingInTitles:([NSSet setWithObjects:@"test 02", @"test", nil])],
                          @"test 03");
    XCTAssertEqualObjects ([@"test 02" stringByUniquingInTitles:([NSSet setWithObjects:@"test 02", @"bla", nil])],
                          @"test 03");
    XCTAssertEqualObjects ([@"test 41" stringByUniquingInTitles:([NSSet setWithObjects:@"test", @"test 41", nil])],
                          @"test 42");
}

- (void)testSelectorCreation
{
    XCTAssertEqualObjects(NSStringFromSelector(PWSelectorByExtendingKeyWithPrefix(@"test", "prefix")), @"prefixTest");
    XCTAssertEqualObjects(NSStringFromSelector(PWSelectorByExtendingKeyWithSuffix(@"test", "Suffix")), @"testSuffix");
    XCTAssertEqualObjects(NSStringFromSelector(PWSelectorByExtendingKeyWithPrefixAndSuffix(@"test", "prefix", "Suffix")), @"prefixTestSuffix");
}

- (void)testStringByReducingWhitespaces
{
    NSString* testString;
    NSString* resultString;
    
    testString = @"Hello,    world!";
    resultString = [testString stringByReducingWhitespaces];
    XCTAssertEqualObjects(@"Hello, world!", resultString);
    XCTAssertTrue(testString != resultString);
    
    testString = @"    reduce spaces at the beginning";
    XCTAssertEqualObjects(@" reduce spaces at the beginning", [testString stringByReducingWhitespaces]);
    
    testString = @"reduce spaces at the end     ";
    XCTAssertEqualObjects(@"reduce spaces at the end ", [testString stringByReducingWhitespaces]);
    
    testString = @"\t\t\treduce tabs at the beginning";
    XCTAssertEqualObjects(@" reduce tabs at the beginning", [testString stringByReducingWhitespaces]);
    
    testString = @"reduce tabs at the end\t\t";
    XCTAssertEqualObjects(@"reduce tabs at the end ", [testString stringByReducingWhitespaces]);
    
    testString = @"\t reduce  \t \tmixed    whitespace\tcharacters";
    XCTAssertEqualObjects(@" reduce mixed whitespace characters", [testString stringByReducingWhitespaces]);
}

- (void)testStringByTrimmingSpaces
{
    XCTAssertEqualObjects(@"some    text", [@" \t  some    text \n\t  " stringByTrimmingSpaces]);
}

- (void)testStringByRemovingSurroundingWhitespaces
{
    XCTAssertEqualObjects(@"some text", [@"   some text\t\t" stringByRemovingSurroundingWhitespace]);
    
    XCTAssertEqualObjects(@"some text\n", [@"  \t  some text\n   " stringByRemovingSurroundingWhitespace]);
    XCTAssertEqualObjects(@"some text\t \n", [@"   some text\t \n   " stringByRemovingSurroundingWhitespace]);
}

- (void)testQuotedPrintableString
{
    XCTAssertEqualObjects([@"test" quotedPrintableStringWithPrefixLength:0 encoding:NSUTF8StringEncoding], @"test");
    XCTAssertEqualObjects([@"test…" quotedPrintableStringWithPrefixLength:0 encoding:NSUTF8StringEncoding], @"=?utf-8?Q?test=E2=80=A6?=");
    XCTAssertEqualObjects([@"täst" quotedPrintableStringWithPrefixLength:0 encoding:NSUTF8StringEncoding], @"=?utf-8?Q?t=C3=A4st?=");
    XCTAssertEqualObjects([@"täst=" quotedPrintableStringWithPrefixLength:0 encoding:NSUTF8StringEncoding], @"=?utf-8?Q?t=C3=A4st=3D?=");
    XCTAssertEqualObjects([@"This is a good test with really quite a lot of fancy characters which should äöü really be broken into a couple of blocks" quotedPrintableStringWithPrefixLength:0 encoding:NSUTF8StringEncoding],
                          @"=?utf-8?Q?This_is_a_good_test_with_really_quite_a_lot_of_fancy_characters_?= =?utf-8?Q?which_should_=C3=A4=C3=B6=C3=BC_really_be_broken_into_a_couple_o?= =?utf-8?Q?f_blocks?=");
}

- (void)testStringFromQuotedPrintable
{
    XCTAssertEqualObjects([NSString stringFromQuotedPrintableString:@"test"], @"test");
    XCTAssertEqualObjects([NSString stringFromQuotedPrintableString:@"The quick brown fox jumps over the lazy dog"], @"The quick brown fox jumps over the lazy dog");
    XCTAssertEqualObjects([NSString stringFromQuotedPrintableString:@"=?UTF-8?Q?test=E2=80=A6?="], @"test…");
    XCTAssertEqualObjects([NSString stringFromQuotedPrintableString:@"=?utf-8?q?t=C3=A4st?="], @"täst");
    XCTAssertEqualObjects([NSString stringFromQuotedPrintableString:@"=?utf-8?Q?t=C3=A4st=3D?="], @"täst=");
    XCTAssertEqualObjects([NSString stringFromQuotedPrintableString:@"=?utf-8?Q?This_is_a_good_test_with_really_quite_a_lot_of_fancy_characters_?=\r\n=?utf-8?Q?which_should_=C3=A4=C3=B6=C3=BC_really_be_broken_into_a_couple_o?=\r\n=?utf-8?Q?f_blocks?="], @"This is a good test with really quite a lot of fancy characters which should äöü really be broken into a couple of blocks");
    XCTAssertEqualObjects([NSString stringFromQuotedPrintableString:@"=?utf-8?Q?This_is_a_good_test_with_really_quite_a_lot_of_fancy_characters_?= =?utf-8?Q?which_should_=C3=A4=C3=B6=C3=BC_really_be_broken_into_a_couple_o?= =?utf-8?Q?f_blocks?="], @"This is a good test with really quite a lot of fancy characters which should äöü really be broken into a couple of blocks");
}

- (void)testBase64Encoding
{
    NSString* testString = @"This is a string to test the base64 encoding capabilities of NSString and NSData";
    NSData* base64Data = [testString dataUsingEncoding:NSUTF8StringEncoding];
    NSString* base64String = [base64Data encodeBase64WithNewlines:YES];
    XCTAssertEqualObjects(base64String, @"VGhpcyBpcyBhIHN0cmluZyB0byB0ZXN0IHRoZSBiYXNlNjQgZW5jb2RpbmcgY2Fw\nYWJpbGl0aWVzIG9mIE5TU3RyaW5nIGFuZCBOU0RhdGE=");
    NSError* error;
    NSData* decodeData = [base64String decodeBase64Error:&error];
    NSString* decodeString = [NSString stringWithData:decodeData encoding:NSUTF8StringEncoding];
    XCTAssertNil(error);
    XCTAssertEqualObjects(decodeString, testString);
}

- (void)testBase64Decoding
{
    NSString* base64String = @"VGhpcyBpcyBzb21lIGRhdGEu";
    NSError* error;
    NSData* decodeData = [base64String decodeBase64Error:&error];
    NSString* decodeString = [NSString stringWithData:decodeData encoding:NSUTF8StringEncoding];
    XCTAssertNil(error);
    XCTAssertEqualObjects(decodeString, @"This is some data.");
}

#pragma mark commpon suffix

- (void)testCommonSuffix
{
    {
        NSString* a = @"";
        NSString* b = @"";
        NSString* testString = [a commonSuffixWithString:b];
        XCTAssertEqualObjects(testString, @"");
    }
    {
        NSString* a = @"m";
        NSString* b = @"mm";
        NSString* testString = [a commonSuffixWithString:b];
        XCTAssertEqualObjects(testString, @"m");
    }
    {
        NSString* a = @"me";
        NSString* b = @"";
        NSString* testString = [a commonSuffixWithString:b];
        XCTAssertEqualObjects(testString, @"");
    }
    {
        NSString* a = @"";
        NSString* b = @"mo";
        NSString* testString = [a commonSuffixWithString:b];
        XCTAssertEqualObjects(testString, @"");
    }
    {
        NSString* a = @"me";
        NSString* b = @"mo";
        NSString* testString = [a commonSuffixWithString:b];
        XCTAssertEqualObjects(testString, @"");
    }
    {
        NSString* a = @"memo";
        NSString* b = @"mo";
        NSString* testString = [a commonSuffixWithString:b];
        XCTAssertEqualObjects(testString, @"mo");
    }
    {
        NSString* a = @"meMo";
        NSString* b = @"mo";
        NSString* testString = [a commonSuffixWithString:b];
        XCTAssertEqualObjects(testString, @"o");
    }
    {
        NSString* a = @"memo";
        NSString* b = @"momemo";
        NSString* testString = [a commonSuffixWithString:b];
        XCTAssertEqualObjects(testString, @"memo");
    }
}

#pragma mark Testing completion

- (void)testCompletionWithOneComponentFromEmptyString
{
    NSString* string = @"f";
    
    NSRange completedRange;
    NSString* completedString = [string completedStringForInsertionIndex:0
                                                               separator:@";"
                                                          completedRange:&completedRange
                                                               completer:^NSArray*(NSString* partialString) {
                                                                   if([partialString isEqualToString:@"f"])
                                                                       return @[@"Frank Blome"];
                                                                   return @[partialString];
                                                               }];
    
    XCTAssertEqualObjects(completedString, @"frank Blome");
    XCTAssertTrue(NSEqualRanges(completedRange, NSMakeRange(1, 10)));
}

- (void)testCompletionWithOneComponentFromNonEmptyString
{
    NSString* string = @"Frank B";
    
    NSRange completedRange;
    NSString* completedString = [string completedStringForInsertionIndex:7
                                                               separator:@";"
                                                          completedRange:&completedRange
                                                               completer:^NSArray*(NSString* partialString) {
                                                                   if([partialString isEqualToString:@"Frank B"])
                                                                       return @[@"Frank Blome"];
                                                                   return @[partialString];
                                                               }];
    
    XCTAssertEqualObjects(completedString, @"Frank Blome");
    XCTAssertTrue(NSEqualRanges(completedRange, NSMakeRange(7, 4)));
}

- (void)testCompletionWithOneComponentFromNonEmptyStringAfterSpace
{
    NSString* string = @"Fran ";
    
    NSRange completedRange;
    NSString* completedString = [string completedStringForInsertionIndex:5
                                                               separator:@";"
                                                          completedRange:&completedRange
                                                               completer:^NSArray*(NSString* partialString) {
                                                                   if([partialString isEqualToString:@"Fran "])
                                                                       return @[@"Fran Miller"];
                                                                   return @[partialString];
                                                               }];
    
    XCTAssertEqualObjects(completedString, @"Fran Miller");
    XCTAssertTrue(NSEqualRanges(completedRange, NSMakeRange(5, 6)));
}

- (void)testCompletionWithTwoComponentsInFirstOne
{
    NSString* string = @"fra; Torsten Radtke";
    
    NSRange completedRange;
    NSString* completedString = [string completedStringForInsertionIndex:3
                                                               separator:@";"
                                                          completedRange:&completedRange
                                                               completer:^NSArray*(NSString* partialString) {
                                                                   if([partialString isEqualToString:@"fra"])
                                                                       return @[@"Frank Blome"];
                                                                   return @[partialString];
                                                               }];
    
    XCTAssertEqualObjects(completedString, @"frank Blome; Torsten Radtke");
    XCTAssertTrue(NSEqualRanges(completedRange, NSMakeRange(3, 8)));
}

- (void)testCompletionWithTwoComponentsInSecondOne
{
    NSString* string = @"Frank Blome; to";
    
    NSRange completedRange;
    NSString* completedString = [string completedStringForInsertionIndex:15
                                                               separator:@";"
                                                          completedRange:&completedRange
                                                               completer:^NSArray*(NSString* partialString) {
                                                                   if([partialString isEqualToString:@"to"])
                                                                       return @[@"Torsten Radtke"];
                                                                   return @[partialString];
                                                               }];
    
    XCTAssertEqualObjects(completedString, @"Frank Blome; torsten Radtke");
    XCTAssertTrue(NSEqualRanges(completedRange, NSMakeRange(15, 12)));
}

- (void)testCompletionWithThreeComponentsInMiddleOne
{
    NSString* string = @"Andreas Känner; ka; Torsten Radtke";
    
    NSRange completedRange;
    NSString* completedString = [string completedStringForInsertionIndex:16
                                                               separator:@";"
                                                          completedRange:&completedRange
                                                               completer:^NSArray*(NSString* partialString) {
                                                                   if([partialString isEqualToString:@"ka"])
                                                                       return @[@"Kai Brüning"];
                                                                   return @[partialString];
                                                               }];
    
    XCTAssertEqualObjects(completedString, @"Andreas Känner; kai Brüning; Torsten Radtke");
    XCTAssertTrue(NSEqualRanges(completedRange, NSMakeRange(18, 9)));
}

- (void)testCompletionWithInsertedSpace
{
    NSString* string = @"Frank Blome ";
    
    NSRange completedRange;
    NSString* completedString = [string completedStringForInsertionIndex:12
                                                               separator:@";"
                                                          completedRange:&completedRange
                                                               completer:^NSArray*(NSString* partialString) {
                                                                   return @[partialString];
                                                               }];
    
    // The completed string is unchanged and the method just returns nil...
    XCTAssertNil(completedString);
    XCTAssertTrue(NSEqualRanges(completedRange, NSMakeRange(12, 0)));
}

- (void)testCompletionWithMultipleSuggestionsWithNoPrefixAndNoSuffix
{
    NSString* string = @"Fra";
    
    NSRange completedRange;
    NSString* completedString = [string completedStringForInsertionIndex:3
                                                               separator:@";"
                                                          completedRange:&completedRange
                                                               completer:^NSArray*(NSString* partialString) {
                                                                   if([partialString isEqualToString:@"Fra"])
                                                                       return @[@"Frank Blome", @"Frank Illenberger"];
                                                                   return @[partialString];
                                                               }];
    
    XCTAssertEqualObjects(completedString, @"Frank Blome");
    XCTAssertTrue(NSEqualRanges(completedRange, NSMakeRange(3, 8)));
}

- (void)testCompletionWithMultipleSuggestionsWithPrefixAndNoSuffix
{
    NSString* string = @"Frank Blome; Fra";
    
    NSRange completedRange;
    NSString* completedString = [string completedStringForInsertionIndex:16
                                                               separator:@";"
                                                          completedRange:&completedRange
                                                               completer:^NSArray*(NSString* partialString) {
                                                                   if([partialString isEqualToString:@"Fra"])
                                                                       return @[@"Frank Blome", @"Frank Illenberger"];
                                                                   return @[partialString];
                                                               }];
    
    XCTAssertEqualObjects(completedString, @"Frank Blome; Frank Illenberger");
    XCTAssertTrue(NSEqualRanges(completedRange, NSMakeRange(16, 14)));
}

- (void)testCompletionWithMultipleSuggestionsWithnoPrefixAndSuffix
{
    NSString* string = @"Fra; Frank Blome";
    
    NSRange completedRange;
    NSString* completedString = [string completedStringForInsertionIndex:3
                                                               separator:@";"
                                                          completedRange:&completedRange
                                                               completer:^NSArray*(NSString* partialString) {
                                                                   if([partialString isEqualToString:@"Fra"])
                                                                       return @[@"Frank Blome", @"Frank Illenberger"];
                                                                   return @[partialString];
                                                               }];
    
    XCTAssertEqualObjects(completedString, @"Frank Illenberger; Frank Blome");
    XCTAssertTrue(NSEqualRanges(completedRange, NSMakeRange(3, 14)));
}
@end
