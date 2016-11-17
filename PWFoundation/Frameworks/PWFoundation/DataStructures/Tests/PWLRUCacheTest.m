//
//  PWLRUCacheTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 08.10.15.
//  Copyright © 2015 ProjectWizards. All rights reserved.
//

#import "PWTestCase.h"
#import "PWLRUCache.h"

@interface PWLRUCacheTest : PWTestCase <PWLRUCacheDelegate>
@end

@implementation PWLRUCacheTest
{
    BOOL _canEvict;
}

- (void)testLRUCacheWithEviction
{
    _canEvict = YES;

    PWLRUCache<NSString*, NSString*>* cache = [[PWLRUCache alloc] initWithCapacity:3
                                                                          delegate:self
                                                                     dispatchQueue:PWDispatchQueue.mainQueue];
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

    [cache evictAsManyObjectsAsPossible];
    XCTAssertEqual(cache.count, 0);
}

- (void)testLRUCacheWithoutEviction
{
    _canEvict = NO;

    PWLRUCache<NSString*, NSString*>* cache = [[PWLRUCache alloc] initWithCapacity:3
                                                                          delegate:self
                                                                     dispatchQueue:PWDispatchQueue.mainQueue];
    
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

    [cache evictAsManyObjectsAsPossible];
    XCTAssertEqual(cache.count, 4);
}

- (BOOL)cache:(PWLRUCache*)cache canEvictObject:(id)object
{
    return _canEvict;
}

- (void)cache:(PWLRUCache*)cache willRemoveObject:(id)object
{

}
@end
