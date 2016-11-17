//
//  PWAsyncLRUCacheTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 24.06.16.
//  Copyright © 2016 ProjectWizards. All rights reserved.
//

#import "PWTestCase.h"
#import "PWAsyncLRUCache.h"

@interface PWAsyncLRUCacheTest : PWTestCase

@end

@implementation PWAsyncLRUCacheTest

- (void)testLRUCacheWithEviction
{
    PWAsyncLRUCache<NSString*, NSString*>* cache;
    cache = [[PWAsyncLRUCache alloc] initWithCapacity:3
                                       removalHandler:^(id key,
                                                        id object,
                                                        BOOL isOptional,
                                                        PWLRUCacheRemovalResponseHandler responseHandler)
             {
                 responseHandler(/* shouldRemove */YES);
             }];
    XCTAssertEqual(cache.count, 0);

    NSString* key1     = [NSMutableString stringWithString:@"k1"];
    NSString* key2     = [NSMutableString stringWithString:@"k2"];
    NSString* key3     = [NSMutableString stringWithString:@"k3"];
    NSString* key4     = [NSMutableString stringWithString:@"k4"];
    NSString* value1   = [NSMutableString stringWithString:@"1"];
    NSString* value2   = [NSMutableString stringWithString:@"2"];
    NSString* value3   = [NSMutableString stringWithString:@"3"];
    NSString* value3_1 = [NSMutableString stringWithString:@"3.1"];
    NSString* value4   = [NSMutableString stringWithString:@"4"];

    XCTAssertNil(cache[key1]);
    XCTAssertNil(cache[key2]);
    XCTAssertNil(cache[key3]);

    cache[key1] = value1;
    XCTAssertEqual(cache.count, 1);
    cache[key2] = value2;
    XCTAssertEqual(cache.count, 2);
    cache[key3] = value3;
    XCTAssertEqual(cache.count, 3);
    XCTAssertEqual(cache[[key1 copy]], value1);
    XCTAssertEqual(cache[[key2 copy]], value2);
    XCTAssertEqual(cache[[key3 copy]], value3);

    cache[key3] = value3_1;
    XCTAssertEqual(cache.count, 3);
    XCTAssertEqual(cache[[key1 copy]], value1);
    XCTAssertEqual(cache[[key2 copy]], value2);
    XCTAssertEqual(cache[[key3 copy]], value3_1);

    cache[key4] = value4;
    XCTAssertEqual(cache.count, 3);
    XCTAssertNil(cache[[key1 copy]]);
    XCTAssertEqual(cache[[key2 copy]], value2);
    XCTAssertEqual(cache[[key3 copy]], value3_1);
    XCTAssertEqual(cache[[key4 copy]], value4);

    cache[key1] = value1;
    XCTAssertEqual(cache.count, 3);
    XCTAssertNil(cache[[key2 copy]]);
    XCTAssertEqual(cache[[key1 copy]], value1);
    XCTAssertEqual(cache[[key3 copy]], value3_1);
    XCTAssertEqual(cache[[key4 copy]], value4);

    XCTestExpectation* expect = [self expectationWithDescription:@"evict"];
    [cache evictAsManyObjectsAsPossibleWithCompletionHandler:^{
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:self.shortTimeout handler:nil];
    XCTAssertEqual(cache.count, 0);
}

- (void)testLRUCacheWithoutEviction
{
    PWAsyncLRUCache<NSString*, NSString*>* cache;
    cache = [[PWAsyncLRUCache alloc] initWithCapacity:3
                                       removalHandler:^(id key,
                                                        id object,
                                                        BOOL isOptional,
                                                        PWLRUCacheRemovalResponseHandler responseHandler)
             {
                 responseHandler(/* shouldRemove */ isOptional ? NO : YES);
             }];

    NSString* key1     = [NSMutableString stringWithString:@"k1"];
    NSString* key2     = [NSMutableString stringWithString:@"k2"];
    NSString* key3     = [NSMutableString stringWithString:@"k3"];
    NSString* key4     = [NSMutableString stringWithString:@"k4"];
    NSString* value1   = [NSMutableString stringWithString:@"1"];
    NSString* value2   = [NSMutableString stringWithString:@"2"];
    NSString* value3   = [NSMutableString stringWithString:@"3"];
    NSString* value3_1 = [NSMutableString stringWithString:@"3.1"];
    NSString* value4   = [NSMutableString stringWithString:@"4"];

    XCTAssertNil(cache[key1]);
    XCTAssertNil(cache[key2]);
    XCTAssertNil(cache[key3]);

    cache[key1] = value1;
    cache[key2] = value2;
    cache[key3] = value3;
    XCTAssertEqual(cache.count, 3);
    XCTAssertEqual(cache[[key1 copy]], value1);
    XCTAssertEqual(cache[[key2 copy]], value2);
    XCTAssertEqual(cache[[key3 copy]], value3);

    cache[key3] = value3_1;
    XCTAssertEqual(cache.count, 3);
    XCTAssertEqual(cache[[key1 copy]], value1);
    XCTAssertEqual(cache[[key2 copy]], value2);
    XCTAssertEqual(cache[[key3 copy]], value3_1);

    cache[key4] = value4;
    XCTAssertEqual(cache.count, 4);
    XCTAssertEqual(cache[[key1 copy]], value1);
    XCTAssertEqual(cache[[key2 copy]], value2);
    XCTAssertEqual(cache[[key3 copy]], value3_1);
    XCTAssertEqual(cache[[key4 copy]], value4);

    cache[key1] = value1;
    XCTAssertEqual(cache.count, 4);
    XCTAssertEqual(cache[[key1 copy]], value1);
    XCTAssertEqual(cache[[key2 copy]], value2);
    XCTAssertEqual(cache[[key3 copy]], value3_1);
    XCTAssertEqual(cache[[key4 copy]], value4);

    XCTestExpectation* expect = [self expectationWithDescription:@"evict"];
    [cache evictAsManyObjectsAsPossibleWithCompletionHandler:^{
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:self.shortTimeout handler:nil];
    XCTAssertEqual(cache.count, 4);
}

- (void)testCreationDuringLookup
{
    PWAsyncLRUCache<NSString*, NSString*>* cache;
    cache = [[PWAsyncLRUCache alloc] initWithCapacity:3
                                       removalHandler:^(id key,
                                                        id object,
                                                        BOOL isOptional,
                                                        PWLRUCacheRemovalResponseHandler responseHandler)
             {
                 responseHandler(/* shouldRemove */YES);
             }];

    NSString* key   = [NSMutableString stringWithString:@"key"];
    NSString* value = [NSMutableString stringWithString:@"value"];

    XCTestExpectation* expect = [self expectationWithDescription:@"lookup"];
    [cache objectForKey:key
          creationBlock:^(id blockKey, PWLRUCacheObjectResponseBlock  responseBlock) {
              XCTAssertEqualObjects(blockKey, key);
              responseBlock(value);
          } completionHandler:^(id blockObject) {
              XCTAssertEqualObjects(blockObject, value);
              [expect fulfill];
          }];
    [self waitForExpectationsWithTimeout:self.shortTimeout handler:nil];
    XCTAssertEqual(cache[key], value);
}

- (void)testRemoveObjectsForKeys
{
    PWAsyncLRUCache<NSString*, NSString*>* cache;
    cache = [[PWAsyncLRUCache alloc] initWithCapacity:3
                                       removalHandler:^(id key,
                                                        id object,
                                                        BOOL isOptional,
                                                        PWLRUCacheRemovalResponseHandler responseHandler)
             {
                 responseHandler(/* shouldRemove */YES);
             }];
    XCTAssertEqual(cache.count, 0);

    NSString* key1     = [NSMutableString stringWithString:@"k1"];
    NSString* key2     = [NSMutableString stringWithString:@"k2"];
    NSString* key3     = [NSMutableString stringWithString:@"k3"];
    NSString* value1   = [NSMutableString stringWithString:@"1"];
    NSString* value2   = [NSMutableString stringWithString:@"2"];
    NSString* value3   = [NSMutableString stringWithString:@"3"];

    cache[key1] = value1;
    cache[key2] = value2;
    cache[key3] = value3;
    XCTAssertEqual(cache.count, 3);

    XCTestExpectation* expect = [self expectationWithDescription:@"remove"];
    [cache removeObjectForKeys:@[key1, key2, key3] completionHandler:^{
        [expect fulfill];
    }];
    [self waitForExpectationsWithTimeout:self.shortTimeout handler:nil];

    XCTAssertNil(cache[key1]);
    XCTAssertNil(cache[key2]);
    XCTAssertNil(cache[key3]);
}
@end
