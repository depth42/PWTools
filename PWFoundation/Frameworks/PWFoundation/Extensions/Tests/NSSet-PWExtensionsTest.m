//
//  NSSet-PWExtensionsTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 05.08.11.
//
//

#import "NSSet-PWExtensionsTest.h"
#import <PWFoundation/PWFoundation.h>

@implementation NSSet_PWExtensionsTest

- (void) testSetWithEnumerable
{
    // nil enumerable results in empty set.
    NSSet* rs = [NSSet setWithEnumerable:nil];
    XCTAssertNotNil (rs);
    XCTAssertEqual (rs.count, (NSUInteger)0);

    // Non-container object as enumerable results in set with this object.
    rs = [NSSet setWithEnumerable:@"test"];
    XCTAssertEqual (rs.count, (NSUInteger)1);
    XCTAssertEqualObjects (rs.anyObject, @"test");
    
    // An immutable set is returned unchanged.
    NSSet* testSet = [NSSet setWithObjects:@"o1", @"o2", @"o3", nil];
    rs = [NSSet setWithEnumerable:testSet];
    XCTAssertEqual (rs, testSet);
    
    // A collection is converted to a set.
    NSArray* testArray = @[@"o1", @"o2", @"o3"];
    rs = [NSSet setWithEnumerable:testArray];
    XCTAssertEqual (rs.count, (NSUInteger)3);
    XCTAssertTrue   ([rs containsObject:@"o2"]);
}

@end
