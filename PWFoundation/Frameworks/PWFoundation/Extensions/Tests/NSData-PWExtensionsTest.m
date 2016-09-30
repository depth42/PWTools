//
//  NSData-PWExtensionsTest.m
//  PWFoundation
//
//  Created by Berbie on 15.01.14.
//
//

#import <XCTest/XCTest.h>

#import "NSData-PWExtensions.h"
#import "PWTestCase.h"

@interface NSData_PWExtensionsTest : PWTestCase

@end

@implementation NSData_PWExtensionsTest

- (void)testBase64Encoding
{
    // validate that encoding between OSX and IOS is identical
    NSString* testString = @"123456789012345678901234567890123456789012345678901234567890";
    NSData* data = [testString dataUsingEncoding:NSUTF8StringEncoding];
    NSString* base64String = [data encodeBase64WithNewlines:YES];
    NSData* base64Data = [base64String dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqual(base64Data.length, (NSUInteger)81); // represents each base64 char plus \n linebreak
}

- (void)testSHA1
{
    NSString* testString = @"123456789012345678901234567890123456789012345678901234567890";
    NSData* data = [testString dataUsingEncoding:NSUTF8StringEncoding];
    NSString* sha1String = data.sha1String;
    XCTAssertEqualObjects(sha1String, @"245be30091fd392fe191f4bfcec22dcb30a03ae6");
}

- (void) testEncodeBase64URL
{
    NSString* testString = @"123456789012345678901234567890123456789012345678901234567890";
    NSData* data = [testString dataUsingEncoding:NSUTF8StringEncoding];
    NSString* encodedString = [data encodeBase64URL];
    
    NSData* decodedData = [[NSData alloc] initWithBase64URLRepresentation:encodedString];
    XCTAssertEqualObjects (decodedData, data);

    [self testEncodeBase64URLRoundtripWithHexString:@"01"];
    [self testEncodeBase64URLRoundtripWithHexString:@"11"];
    [self testEncodeBase64URLRoundtripWithHexString:@"ff"];
    [self testEncodeBase64URLRoundtripWithHexString:@"ff123234532986789043"];
    [self testEncodeBase64URLRoundtripWithHexString:@"ff123234532986789043abcdef"];
}

- (void) testEncodeBase64URLRoundtripWithHexString:(NSString*)testDataString
{
    NSData* data = [NSData dataWithHexadecimalRepresentation:testDataString];
    NSString* encodedString = [data encodeBase64URL];
    NSData* decodedData = [[NSData alloc] initWithBase64URLRepresentation:encodedString];
    XCTAssertEqualObjects (decodedData, data);

    NSString* decodedString = [decodedData hexadecimalRepresentation];
    XCTAssertEqualObjects (decodedString, testDataString);
}

@end
