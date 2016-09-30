//
//  PWValueGroupTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 13.04.13.
//
//

#import "PWValueGroupTest.h"
#import "PWValueGroup.h"
#import "NSArray-PWExtensions.h"

@implementation PWValueGroupTest

- (void)testCreation
{
    PWValueGroup* group = [[PWValueGroup alloc] init];
    XCTAssertEqualObjects(group.deepValues, @[]);
    XCTAssertEqual(group.count, (NSUInteger)0);
    XCTAssertEqual(group.type, PWValueGroupTypeRoot);
    XCTAssertNil(group.name);
    XCTAssertFalse(group.isImmutable);
}

- (void)testMutability
{
    PWValueGroup* group = [[PWValueGroup alloc] init];
    XCTAssertFalse(group.isImmutable);
    group.name = @"name";
    group.type = PWValueGroupTypeWeak;
    [group addValue:@"test"];

    PWValueGroup* subGroup = [[PWValueGroup alloc] init];
    XCTAssertFalse(subGroup.isImmutable);
    [group addGroup:subGroup];

    [group makeImmutable];
    XCTAssertTrue(group.isImmutable);
    XCTAssertTrue(subGroup.isImmutable);

    XCTAssertThrows(group.name = @"test");
    XCTAssertThrows(group.type = PWValueGroupTypeStrong);
    XCTAssertThrows([group addValue:@"test"]);
    XCTAssertThrows([group addGroup:subGroup]);
}

- (void)testGroupWithValues
{
    NSArray* values = @[@"A", @"B", @"C"];
    PWValueGroup* group = [PWValueGroup groupWithValues:values];
    XCTAssertEqualObjects(group.deepValues, values);
    XCTAssertEqual(group.count, values.count);
    XCTAssertEqual(group.type, PWValueGroupTypeRoot);
    XCTAssertNil(group.name);
    XCTAssertTrue(group.isImmutable);

    PWValueGroup* group2 = [PWValueGroup groupWithValues:nil];
    XCTAssertEqualObjects(group2.deepValues, @[]);
    XCTAssertEqual(group2.count, (NSUInteger)0);
    XCTAssertEqual(group2.type, PWValueGroupTypeRoot);
    XCTAssertNil(group2.name);
    XCTAssertTrue(group2.isImmutable);
}

- (void)testAddingValues
{
    PWValueGroup* group = [[PWValueGroup alloc] init];
    [group addValue:@"A" withCategory:PWValueCategoryBasic];
    [group addValue:@"B" withCategory:PWValueCategoryExtended];
    [group addValue:@"C"];

    PWValueGroup* subGroup1 = [[PWValueGroup alloc] init];
    [subGroup1 addValue:@"D"];
    [group addGroup:subGroup1 withCategory:PWValueCategoryExtended];
    
    PWValueGroup* subGroup2 = [[PWValueGroup alloc] init];
    [subGroup1 addValue:@"E"];
    [group addGroup:subGroup2];

    NSArray* array = [self enumeratedGroup:group withCategories:PWValueCategoryMaskAll];
    XCTAssertEqualObjects(array, (@[
                                 @{@"value": @"A",      @"category": @(PWValueCategoryBasic)},
                                 @{@"value": @"B",      @"category": @(PWValueCategoryExtended)},
                                 @{@"value": @"C",      @"category": @(PWValueCategoryBasic)},
                                 @{@"group": subGroup1, @"category": @(PWValueCategoryExtended)},
                                 @{@"group": subGroup2, @"category": @(PWValueCategoryBasic)},
                                 ]));

    array = [self enumeratedGroup:group withCategories:PWValueCategoryMaskBasic];
    XCTAssertEqualObjects(array, (@[
                                 @{@"value": @"A",      @"category": @(PWValueCategoryBasic)},
                                 @{@"value": @"C",      @"category": @(PWValueCategoryBasic)},
                                 @{@"group": subGroup2, @"category": @(PWValueCategoryBasic)},
                                 ]));

    array = [self enumeratedGroup:group withCategories:PWValueCategoryMaskExtended];
    XCTAssertEqualObjects(array, (@[
                                 @{@"value": @"B",      @"category": @(PWValueCategoryExtended)},
                                 @{@"group": subGroup1, @"category": @(PWValueCategoryExtended)},
                                 ]));


    XCTAssertEqualObjects(group.deepValues, (@[@"A", @"B", @"C", @"D", @"E"]));
    XCTAssertEqual(group.count, (NSUInteger)5);

    PWValueCategory category;
    XCTAssertTrue([group deepContainsValue:@"A" category:&category]);
    XCTAssertEqual(category, PWValueCategoryBasic);
    XCTAssertTrue([group deepContainsValue:@"B" category:&category]);
    XCTAssertEqual(category, PWValueCategoryExtended);
    XCTAssertTrue([group deepContainsValue:@"E" category:&category]);
    XCTAssertEqual(category, PWValueCategoryBasic);
    XCTAssertFalse([group deepContainsValue:@"G" category:&category]);
}

- (NSArray*)enumeratedGroup:(PWValueGroup*)group withCategories:(PWValueCategoryMask)categories
{
    NSMutableArray* array = [NSMutableArray array];
    [group enumerateWithCategories:categories
                        usingBlock:^(id iValue, PWValueGroup *iGroup, PWValueCategory iCategory, BOOL *stop) {
                            NSMutableDictionary* dict = [NSMutableDictionary dictionary];
                            if(iValue)
                                dict[@"value"] = iValue;
                            if(iGroup)
                                dict[@"group"] = iGroup;
                            dict[@"category"] = @(iCategory);
                            [array addObject:dict];
                        }];
    return array;
}
@end
