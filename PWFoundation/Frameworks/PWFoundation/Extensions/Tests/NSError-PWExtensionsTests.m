//
//  NSError-PWExtensionsTests.m
//  PWFoundation
//
//  Created by Berbie on 06.11.15.
//
//

#import "PWTestCase.h"

#import "NSError-PWExtensions.h"

@interface NSError_PWExtensionsTests : PWTestCase
@end

@implementation NSError_PWExtensionsTests

- (void)testErrorOrigin
{
    {
        NSError* error;
        XCTAssertTrue([self errorWithBoolReturn:&error]);
        XCTAssertNotNil(error.userInfo[PWErrorOriginErrorKey]);
        XCTAssertEqualObjects(error.userInfo[PWErrorContextErrorKey], @"errorWithBoolReturn:");
    }

    {
        NSError* error;
        XCTAssertEqualObjects([self errorWithStringReturn:&error], @"returnString");
        XCTAssertNotNil(error.userInfo[PWErrorOriginErrorKey]);
        XCTAssertEqualObjects(error.userInfo[PWErrorContextErrorKey], @"errorWithStringReturn:");
    }

    {
        XCTAssertEqualObjects([self errorWithStringReturn:nil], @"returnString");
    }
}

#pragma mark helper

- (BOOL)errorWithBoolReturn:(inout NSError* _Nullable*_Nullable)error
{
    if (error) *error = [NSError ensureError:nil];
    return PWErrorRefEnsureOrigin(error, NSStringFromSelector(_cmd), YES);
}

- (NSString*)errorWithStringReturn:(inout NSError* _Nullable*_Nullable)error
{
    if (error) *error = [NSError ensureError:nil];
    return PWErrorRefEnsureOrigin(error, NSStringFromSelector(_cmd), @"returnString");
}

@end
