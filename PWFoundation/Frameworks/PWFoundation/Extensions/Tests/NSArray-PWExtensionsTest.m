//
//  NSArray-PWExtensionsTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 10/20/10.
//
//

#import "NSArray-PWExtensionsTest.h"
#import "PWSortDescriptor.h"
#import "NSArray-PWExtensions.h"
#import "NSMutableArray-PWExtensions.h"
#import "NSString-PWExtensions.h"

@implementation NSArray_PWExtensionsTest

- (void) testMap
{
    NSArray* source = @[@"one", @"two", @"three"];

    NSArray* mapped = [source map:^id(id obj) {
        return [(NSString*)obj stringWithUppercaseFirstLetter];
    }];
    XCTAssertEqualObjects (mapped, (@[@"One", @"Two", @"Three"]));

    mapped = [source map:^id(id obj) {
        return obj;
    }];
    XCTAssertEqual (mapped, source);

    mapped = [source map:^id(id obj) {
        NSString* str = obj;
        return [str isEqualToString:@"two"] ? [str stringWithUppercaseFirstLetter] : str;
    }];
    XCTAssertEqualObjects (mapped, (@[@"one", @"Two", @"three"]));
    
    mapped = [source map:^id(id obj) {
        NSString* str = obj;
        return [str isEqualToString:@"two"] ? nil : str;
    }];
    XCTAssertEqualObjects (mapped, (@[@"one", [NSNull null], @"three"]));

    __block BOOL seenTwo = NO;
    mapped = [source map:^id(id obj) {
        NSString* str = obj;
        if (seenTwo)
            return nil;
        if ([str isEqualToString:@"two"]) {
            seenTwo = YES;
            return [str stringWithUppercaseFirstLetter];
        }
        return str;
    }];
    XCTAssertEqualObjects (mapped, (@[@"one", @"Two", [NSNull null]]));
}

- (void) testMapWithoutNull
{
    NSArray* source = @[@"one", @"two", @"three"];
    
    NSArray* mapped = [source mapWithoutNull:^id(id obj) {
        return [(NSString*)obj stringWithUppercaseFirstLetter];
    }];
    XCTAssertEqualObjects (mapped, (@[@"One", @"Two", @"Three"]));
    
    mapped = [source mapWithoutNull:^id(id obj) {
        return obj;
    }];
    XCTAssertEqual (mapped, source);
    
    mapped = [source mapWithoutNull:^id(id obj) {
        NSString* str = obj;
        return [str isEqualToString:@"two"] ? [str stringWithUppercaseFirstLetter] : str;
    }];
    XCTAssertEqualObjects (mapped, (@[@"one", @"Two", @"three"]));
    
    mapped = [source mapWithoutNull:^id(id obj) {
        NSString* str = obj;
        return [str isEqualToString:@"two"] ? nil : str;
    }];
    XCTAssertEqualObjects (mapped, (@[@"one", @"three"]));
    
    __block BOOL seenTwo = NO;
    mapped = [source mapWithoutNull:^id(id obj) {
        NSString* str = obj;
        if (seenTwo)
            return nil;
        if ([str isEqualToString:@"two"]) {
            seenTwo = YES;
            return [str stringWithUppercaseFirstLetter];
        }
        return str;
    }];
    XCTAssertEqualObjects (mapped, (@[@"one", @"Two"]));
}

- (void) testAsynchronouslyEnumerateObjects
{
    NSArray* testArray = @[@0, @1, @2, @3];

    // Test all synchronous use.
    __block NSUInteger index = 0;
    [testArray asynchronouslyEnumerateObjectsUsingBlock:^(id object,
                                                          PWAsynchronousEnumerationObjectCompletionHandler objectCompletionHandler)
     {
         XCTAssertEqualObjects (object, @(index++));
         objectCompletionHandler (/*stop =*/NO, /*error =*/nil);
     }
                                              completionHandler:^(BOOL didFinish, NSError* lastError)
     {
         XCTAssertTrue (didFinish);
     }];
    XCTAssertEqual (index, 4);

    // Test actually asynchronous enumeration.
    XCTestExpectation* expectation = [self expectationWithDescription:@"asynchronous enumeration 1 done"];
    index = 0;
    [testArray asynchronouslyEnumerateObjectsUsingBlock:^(id object,
                                                          PWAsynchronousEnumerationObjectCompletionHandler objectCompletionHandler)
     {
         XCTAssertEqualObjects (object, @(index++));
         [PWDispatchQueue.mainQueue asynchronouslyDispatchBlock:^{
             objectCompletionHandler (/*stop =*/NO, /*error =*/nil);
         }];
     }
                                      completionHandler:^(BOOL didFinish, NSError* lastError)
     {
         XCTAssertTrue (didFinish);
         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:self.normalTimeout handler:nil];
    XCTAssertEqual (index, 4);
    
    // Test stopping prematurely.
    expectation = [self expectationWithDescription:@"asynchronous enumeration 2 done"];
    index = 0;
    [testArray asynchronouslyEnumerateObjectsUsingBlock:^(id object,
                                                          PWAsynchronousEnumerationObjectCompletionHandler objectCompletionHandler)
     {
         XCTAssertEqualObjects (object, @(index++));
         [PWDispatchQueue.mainQueue asynchronouslyDispatchBlock:^{
             objectCompletionHandler (/*stop =*/index >= 2, /*error =*/nil);
         }];
     }
                                      completionHandler:^(BOOL didFinish, NSError* lastError)
     {
         XCTAssertFalse (didFinish);
         [expectation fulfill];
     }];
    [self waitForExpectationsWithTimeout:self.normalTimeout handler:nil];
    XCTAssertEqual (index, 2);
}

- (void) testIsEqualFuzzy
{
    NSArray* a1 = @[@"one", @"two", @"three"];
    NSArray* a2 = @[@"one", @"two", @"three"];
    NSArray* a3 = @[@"one", @"Two", @"three"];
    NSArray* a4 = @[@"one", @"two"];
    
    XCTAssertTrue  ([a1 isEqualFuzzy:a2]);
    XCTAssertTrue  ([a2 isEqualFuzzy:a1]);
    XCTAssertFalse ([a1 isEqualFuzzy:a3]);
    XCTAssertFalse ([a3 isEqualFuzzy:a1]);
    XCTAssertFalse ([a1 isEqualFuzzy:a4]);
    XCTAssertFalse ([a4 isEqualFuzzy:a1]);
    
    NSArray* a5 = @[@1.0, @3.0];
    NSArray* a6 = @[@1.0, @3.0];
    NSArray* a7 = @[@1.0, @3.0000000000001];
    NSArray* a8 = @[@1.0, @3.000001];

    XCTAssertTrue  ([a5 isEqualFuzzy:a6]);
    XCTAssertTrue  ([a6 isEqualFuzzy:a5]);
    XCTAssertTrue  ([a5 isEqualFuzzy:a7]);
    XCTAssertTrue  ([a7 isEqualFuzzy:a5]);
    XCTAssertFalse ([a5 isEqualFuzzy:a8]);
    XCTAssertFalse ([a8 isEqualFuzzy:a5]);
}

- (void)testEnumerateCombinationPairs
{
    NSArray* testArray = @[@(1), @(2), @(1), @(3)];
    NSMutableArray* testEvents = [NSMutableArray array];
    [testArray enumerateCombinationPairsUsingBlock:^(id obj1, id obj2, BOOL *stop) {
        [testEvents addObject:[NSString stringWithFormat:@"%@-%@", obj1, obj2]];
    }];
    NSArray* expectedEvents = @[
                                @"1-2",
                                @"1-3",
                                @"2-3",
                                ];
    XCTAssertEqualObjects(testEvents, expectedEvents);
}

@end
