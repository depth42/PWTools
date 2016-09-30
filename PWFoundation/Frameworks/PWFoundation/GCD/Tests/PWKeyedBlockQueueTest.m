//
//  PWKeyedBlockQueueTest.m
//  PWAppKit
//
//  Created by Frank Illenberger on 17.11.12.
//
//

#import "PWKeyedBlockQueueTest.h"
#import "PWKeyedBlockQueue.h"

@implementation PWKeyedBlockQueueTest

- (void)testDirectPerform
{
    PWKeyedBlockQueue* queue = [[PWKeyedBlockQueue alloc] init];
    XCTAssertFalse(queue.isSuspended);
    __block BOOL didCall = NO;
    [queue forKey:@"k1" performBlock:^{
        didCall = YES;
    }];
    XCTAssertTrue(didCall);
    [queue dispose];
}

- (void)testSuspendedPerform
{
    PWKeyedBlockQueue* queue = [[PWKeyedBlockQueue alloc] init];
    XCTAssertFalse(queue.isSuspended);
    [queue suspend];
    XCTAssertTrue(queue.isSuspended);

    __block NSUInteger callCount1 = 0;
    __block NSUInteger callCount2 = 0;
    [queue forKey:@"k1" performBlock:^{
        XCTAssertEqual(callCount2, (NSUInteger)0);
        callCount1++;
    }];

    [queue forKey:@"k2" performBlock:^{
        callCount2++;
    }];
    XCTAssertEqual(callCount1, (NSUInteger)0);
    XCTAssertEqual(callCount2, (NSUInteger)0);

    [queue resume];
    XCTAssertEqual(callCount1, (NSUInteger)1);
    XCTAssertEqual(callCount2, (NSUInteger)1);
    XCTAssertFalse(queue.isSuspended);
    [queue dispose];
}

- (void)testPerformByKey
{
    PWKeyedBlockQueue* queue = [[PWKeyedBlockQueue alloc] init];
    [queue suspend];

    __block NSUInteger callCount1 = 0;
    __block NSUInteger callCount2 = 0;
    [queue forKey:@"k1" performBlock:^{
        callCount1++;
    }];

    [queue forKey:@"k2" performBlock:^{
        callCount2++;
    }];

    [queue performPendingBlockForKey:@"k1"];
    XCTAssertEqual(callCount1, (NSUInteger)1);
    XCTAssertEqual(callCount2, (NSUInteger)0);
    XCTAssertTrue(queue.isSuspended);

    [queue resume];
    XCTAssertEqual(callCount1, (NSUInteger)1);
    XCTAssertEqual(callCount2, (NSUInteger)1);
    XCTAssertFalse(queue.isSuspended);
    [queue dispose];
}

@end
