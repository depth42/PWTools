//
//  NSBundle-PWExtensionsTest.m
//  PWFoundation
//
//  Created by Andreas Känner on 29.05.09.
//
//

#import "NSBundle-PWExtensionsTest.h"
#import "NSBundle-PWExtensions.h"

@implementation NSBundle_PWExtensionsTest

- (void) testCompareVersion
{
    XCTAssertEqual ([NSBundle compareVersion:@""        withVersion:@""],           (NSComparisonResult)NSOrderedSame);

    XCTAssertEqual ([NSBundle compareVersion:@"1"       withVersion:@"2"],          (NSComparisonResult)NSOrderedAscending);
    XCTAssertEqual ([NSBundle compareVersion:@"2"       withVersion:@"2"],          (NSComparisonResult)NSOrderedSame);
    XCTAssertEqual ([NSBundle compareVersion:@"2"       withVersion:@"1"],          (NSComparisonResult)NSOrderedDescending);

    XCTAssertEqual ([NSBundle compareVersion:@"1.2"     withVersion:@"1.2"],        (NSComparisonResult)NSOrderedSame);
    XCTAssertEqual ([NSBundle compareVersion:@"1.2"     withVersion:@"1.3"],        (NSComparisonResult)NSOrderedAscending);
    XCTAssertEqual ([NSBundle compareVersion:@"1.2"     withVersion:@"1.0"],        (NSComparisonResult)NSOrderedDescending);
    XCTAssertEqual ([NSBundle compareVersion:@"1.2"     withVersion:@"0.3"],        (NSComparisonResult)NSOrderedDescending);

    XCTAssertEqual ([NSBundle compareVersion:@"1.2"     withVersion:@"1.2.0"],      (NSComparisonResult)NSOrderedAscending);
    XCTAssertEqual ([NSBundle compareVersion:@"1.2.0"   withVersion:@"1.2"],        (NSComparisonResult)NSOrderedDescending);

    XCTAssertEqual ([NSBundle compareVersion:@"1.2.3"   withVersion:@"1.1.3"],      (NSComparisonResult)NSOrderedDescending);
    XCTAssertEqual ([NSBundle compareVersion:@"1.2.3"   withVersion:@"1.3.3"],      (NSComparisonResult)NSOrderedAscending);
}

@end
