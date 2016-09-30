//
//  PWOrderedDictionaryTest.m
//  PWFoundation
//
//  Created by Kai on 2.6.10.
//
//

#import "PWOrderedDictionaryTest.h"
#import "PWOrderedDictionary.h"


@implementation PWOrderedDictionaryTest

- (void) testMutableOrderedDictionary:(PWMutableOrderedDictionary*)dict
{
    NSString* keys[] = { @"m1", @"c2", @"x3", @"e4", @"z5", @"t6", @"g7" };
    NSString* const * keysPtr = keys;
    
    NSMutableString* v6 = [NSMutableString stringWithString:@"v6"];
    dict[keys[0]] = @"v1";
    dict[keys[1]] = @"v2";
    dict[keys[2]] = @"v3";
    dict[keys[3]] = @"v4";
    dict[keys[4]] = @"v5";
    dict[keys[5]] = v6;
    dict[keys[6]] = @"v7";
    
    // Test lookup. Note: values are not copied by a dictionary.
    XCTAssertEqualObjects (dict[keys[1]], @"v2");
    XCTAssertEqual       (dict[keys[5]], v6);
    
    
    // Test fast enumeration.
    __block int i = 0;
    for (NSString* iKey in dict) {
        XCTAssertEqualObjects (iKey, keys[i++]);
    }
    
    // Test block-based enumeration.
    i = 0;
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        XCTAssertEqualObjects (key, keysPtr[i++]);
    }];
    
    
    // Replacing a key moves it to the back.
    dict[keys[2]] = @"v6";
    i = 0;
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        if (i == 7)
            i = 2;
        XCTAssertEqualObjects (key, keysPtr[i++]);
        if (i == 2)
            ++i;
    }];
    
    // Test removal of a key.
    [dict removeObjectForKey:keys[4]];
    i = 0;
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        if (i == 7)
            i = 2;
        XCTAssertEqualObjects (key, keysPtr[i++]);
        if (i == 2 || i == 4)
            ++i;
    }];
    
    // Test the enumeration cancellation.
    i = 0;
    [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        if (obj == v6)
            *stop = YES;
        else
            ++i;
    }];
    XCTAssertEqual (i, 3);
}

- (void) testMutableOrderedDictionary
{
    PWMutableOrderedDictionary* dict1 = [[PWMutableOrderedDictionary alloc] init];
    [self testMutableOrderedDictionary:dict1];
    
    // Different initializer:
    PWMutableOrderedDictionary* dict2 = [PWMutableOrderedDictionary dictionaryWithCapacity:10];
    [self testMutableOrderedDictionary:dict2];
}

- (void) testMutableOrderedDictionary2
{
    NSString* keys[] = { @"m1", @"c2", @"x3", @"e4", @"z5", @"t6", @"g7" };
    NSMutableString* v6 = [NSMutableString stringWithString:@"v6"];
    
    PWMutableOrderedDictionary* dict = [PWMutableOrderedDictionary dictionaryWithObjectsAndKeys:
                                        @"v1", keys[0],
                                        @"v2", keys[1],
                                        @"v3", keys[2],
                                        @"v4", keys[3],
                                        @"v5", keys[4],
                                        v6   , keys[5],
                                        @"v7", keys[6], nil];
    __block int i = 0;
    for (NSString* iKey in dict) {
        XCTAssertEqualObjects (iKey, keys[i++]);
    }
}

@end
