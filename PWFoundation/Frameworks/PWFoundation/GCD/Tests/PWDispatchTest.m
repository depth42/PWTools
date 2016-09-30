#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5

//
//  PWDispatchTest
//  PWFoundation
//
//  Created by Kai Brüning on 18.6.09.
//
//

#import "PWDispatchTest.h"
#import <dispatch/dispatch.h>
#import <PWFoundation/PWDispatch.h>
#import "NSObject-PWExtensions.h"
#import "PWDispatchingTestImplementation.h"
#include <libkern/OSAtomic.h>

@interface PWDispatchTest ()
- (void) runCurrentRunLoopUntilNothingMoreToDo;
@end


@implementation PWDispatchTest

- (void) testBasicProxy
{
    XCTAssertEqual (PWDispatchQueue.mainQueue.underlyingQueue, dispatch_get_main_queue(),
                    @"main queue does not match");
    XCTAssertEqual ([PWDispatchQueue globalLowPriorityQueue].underlyingQueue,
                    dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_LOW, 0),
                    @"low priority queue does not match");
    XCTAssertEqual ([PWDispatchQueue globalDefaultPriorityQueue].underlyingQueue,
                    dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                    @"default priority queue does not match");
    XCTAssertEqual ([PWDispatchQueue globalHighPriorityQueue].underlyingQueue,
                    dispatch_get_global_queue (DISPATCH_QUEUE_PRIORITY_HIGH, 0),
                    @"high priority queue does not match");
    
    PWDispatchQueue* testQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"test"];
    XCTAssertNotNil (testQueue, @"could not create a serial queue");
    XCTAssertEqualObjects (testQueue.label, @"test", @"label does not match");
}

- (void) testIsCurrent
{
    PWDispatchQueue* q1 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q1"];
    PWDispatchQueue* q2 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q1"];
    PWDispatchQueue* mq = PWDispatchQueue.mainQueue;

    XCTAssertTrue (mq.isCurrentDispatchQueue);
    XCTAssertFalse(q1.isCurrentDispatchQueue);
    XCTAssertFalse(q2.isCurrentDispatchQueue);

    [q1 synchronouslyDispatchBlock:^{
        XCTAssertTrue (mq.isCurrentDispatchQueue);
        XCTAssertTrue (q1.isCurrentDispatchQueue);
        XCTAssertFalse(q2.isCurrentDispatchQueue);
        [q2 synchronouslyDispatchBlock:^{
            XCTAssertTrue (mq.isCurrentDispatchQueue);
            XCTAssertTrue (q1.isCurrentDispatchQueue);
            XCTAssertTrue (q2.isCurrentDispatchQueue);
        }];
        XCTAssertTrue (mq.isCurrentDispatchQueue);
        XCTAssertTrue (q1.isCurrentDispatchQueue);
        XCTAssertFalse(q2.isCurrentDispatchQueue);
    }];

    XCTAssertTrue (mq.isCurrentDispatchQueue);
    XCTAssertFalse(q1.isCurrentDispatchQueue);
    XCTAssertFalse(q2.isCurrentDispatchQueue);

    XCTestExpectation* expectation = [self expectationWithDescription:@"inner block called"];
    [q1 asynchronouslyDispatchBlock:^{
        XCTAssertTrue(q1.isCurrentDispatchQueue);
        XCTAssertFalse(mq.isCurrentDispatchQueue);
        [q2 synchronouslyDispatchBlock:^{
            [q1 synchronouslyDispatchBlock:^{   // recursion test
                XCTAssertFalse(mq.isCurrentDispatchQueue);
                XCTAssertTrue (q1.isCurrentDispatchQueue);
                XCTAssertTrue (q2.isCurrentDispatchQueue);
                [expectation fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:self.longTimeout handler:nil];
}

- (void) testIsCurrentMainQueue
{
    PWDispatchQueue* q1 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q1"];
    PWDispatchQueue* mq = PWDispatchQueue.mainQueue;
    XCTestExpectation* expectation = [self expectationWithDescription:@"inner block called"];

    [q1 asynchronouslyDispatchBlock:^{
        [mq synchronouslyDispatchBlock:^{
            XCTAssertTrue (mq.isCurrentDispatchQueue);
            XCTAssertTrue (q1.isCurrentDispatchQueue);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:self.longTimeout handler:nil];
}

- (void) testSyncDispatchBlock
{
    __block BOOL blockDidRun = NO;
    
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:@"testqueue"];
    [queue synchronouslyDispatchBlock:^{ blockDidRun = YES; }];

    XCTAssertTrue (blockDidRun, @"synchronously dispatched block did not run");
}

- (void) testSyncDispatchBlockWithIterationCount
{    
    __block NSMutableSet* blocksDidRun = [NSMutableSet set];
    
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:@"testqueue"];
    [queue synchronouslyDispatchBlock:^(size_t i){
        [blocksDidRun addObject:@(i)];
    } times:10];
    
    for (int i = 0; i < 10; ++i)
        XCTAssertTrue ([blocksDidRun containsObject:@(i)], @"synchronously dispatched block %i did not run", i);
}

- (void) testAsyncDispatchBlock
{
    __block BOOL blockDidRun = NO;
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"block did run"];
    [PWDispatchQueue.globalLowPriorityQueue asynchronouslyDispatchBlock:^{
        blockDidRun = YES;
        [PWDispatchQueue.mainQueue asynchronouslyDispatchBlock:^{
            XCTAssertTrue (blockDidRun, @"asynchronously dispatched block did not run");
            [expectation fulfill];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:self.shortTimeout handler:nil];
}

- (void) testDispatchGroup
{
    __block BOOL block1DidRun = NO;
    __block BOOL block2DidRun = NO;
    __block BOOL block3DidRun = NO;
    
    PWDispatchGroup* group = [[PWDispatchGroup alloc] init];
    PWDispatchQueue* queue = [PWDispatchQueue globalDefaultPriorityQueue];
    
    [queue asynchronouslyDispatchBlock:^{ block1DidRun = YES; } inGroup:group];
    [queue asynchronouslyDispatchBlock:^{ block2DidRun = YES; } inGroup:group];
    [queue asynchronouslyDispatchBlock:^{ block3DidRun = YES; } inGroup:group];
    
    BOOL success = [group waitForCompletionWithTimeout:self.longTimeout useWallTime:NO];
    XCTAssertTrue (success, @"waiting for a group failed");

    XCTAssertTrue (block1DidRun, @"asynchronously dispatched block 1 did not run");
    XCTAssertTrue (block2DidRun, @"asynchronously dispatched block 2 did not run");
    XCTAssertTrue (block3DidRun, @"asynchronously dispatched block 3 did not run");
}

- (void) testIntegrationWithNSOperationQueue
{
    PWDispatchQueue* dispatchQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"testqueue"];
    NSOperationQueue* opQueue = [[NSOperationQueue alloc] init];
    opQueue.underlyingQueue = dispatchQueue.underlyingQueue;
    
    XCTestExpectation* expectation = [self expectationWithDescription:@"block did run"];
    [opQueue addOperationWithBlock:^{
        XCTAssertFalse (dispatchQueue.isCurrentDispatchQueue);
        [dispatchQueue asCurrentQueuePerformBlock:^{
            XCTAssertTrue (dispatchQueue.isCurrentDispatchQueue);
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:self.shortTimeout handler:nil];
}

- (void) runCurrentRunLoopUntilNothingMoreToDo
{
    NSRunLoop* currentRunLoop = [NSRunLoop currentRunLoop]; 
    
    // run the current run loop until the date of the next timer lies in the future
    BOOL keepOn = YES;
    while (keepOn) {
        NSDate* limitDate = [currentRunLoop limitDateForMode:NSDefaultRunLoopMode];
        if (!limitDate || (limitDate && (limitDate.timeIntervalSinceNow > 0.0)))
            keepOn = NO;
    }
}

- (void)testDispatchSemaphore
{
    PWDispatchSemaphore* semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    __block BOOL blockDidRun = NO;
    [queue asynchronouslyDispatchBlock:^{
        blockDidRun = YES;
        [semaphore signal];
    }];
    XCTAssertTrue([semaphore waitWithTimeout:0.1 useWallTime:YES]);
    XCTAssertTrue(blockDidRun);
}

- (void)testDispatchSemaphoreTimeout
{
    PWDispatchSemaphore* semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    __block BOOL timeoutPassed = NO;
    [[PWDispatchQueue globalDefaultPriorityQueue] asynchronouslyDispatchBlock:^{
        [NSThread sleepForTimeInterval:0.1];
        // Note: need to use atomic functions here to make TSan happy.
        XCTAssertTrue(OSAtomicTestAndClear (7, &timeoutPassed));
        [semaphore signal];
    }];
    XCTAssertFalse([semaphore waitWithTimeout:0.02 useWallTime:NO]);
    XCTAssertFalse(OSAtomicTestAndSet (7, &timeoutPassed));
}

// Timers do not seem to work correctly under iOS framework tests. radar://21399290
// Therefore we disable the timer tests under iOS.
#if UXTARGET_OSX

- (void)testDispatchTimerSingle
{
    PWDispatchTimer* timer = [[PWDispatchTimer alloc] initWithQueue:[PWDispatchQueue globalDefaultPriorityQueue]];
    [timer setFireIntervalFromNow:0.05 leeway:0.01 useWallTime:YES];
    __block int32_t fireCount = 0;
    [timer setEventBlock:^{
        OSAtomicIncrement32(&fireCount);
    }];
    [timer enable];
    [NSThread sleepForTimeInterval:0.1];
    [timer cancel];
    XCTAssertEqual(fireCount, 1);
}

- (void)testDispatchTimerSingleWithConvenienceMethod
{
    __block int32_t fireCount = 0;
    PWDispatchTimer* timer = [PWDispatchTimer enabledSingleShotTimerWithQueue:[PWDispatchQueue globalDefaultPriorityQueue]
                                                          fireIntervalFromNow:0.05
                                                                       leeway:0.01
                                                                  useWallTime:YES
                                                                   eventBlock:^{
                                                                       OSAtomicIncrement32(&fireCount);
                                                                   }];
    [NSThread sleepForTimeInterval:0.1];
    [timer cancel];
    XCTAssertEqual(fireCount, 1);
}

- (void)testDispatchTimerSingleOnMainThread
{
    PWDispatchTimer* timer = [[PWDispatchTimer alloc] initWithQueue:PWDispatchQueue.mainQueue];
    [timer setFireIntervalFromNow:0.05 leeway:0.01 useWallTime:YES];
    __block int32_t fireCount = 0;
    [timer setEventBlock:^{
        OSAtomicIncrement32(&fireCount);
        XCTAssertTrue(PWDispatchQueue.mainQueue.isCurrentDispatchQueue);
    }];
    [timer enable];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [timer cancel];
    XCTAssertEqual(fireCount, 1);
}

- (void)testDispatchTimerSingleOnMainThreadWithConvenienceMethod
{
    __block NSUInteger fireCount = 0;
    PWDispatchTimer* timer = [PWDispatchTimer enabledSingleShotTimerWithQueue:PWDispatchQueue.mainQueue
                                                          fireIntervalFromNow:0.05
                                                                       leeway:0.01
                                                                  useWallTime:YES
                                                                   eventBlock:^{
                                                                       fireCount++;
                                                                       XCTAssertTrue(PWDispatchQueue.mainQueue.isCurrentDispatchQueue);
                                                                  }];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    [timer cancel];
    XCTAssertEqual(fireCount, 1);
}

- (void)testDispatchTimerMultiple
{
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    PWDispatchTimer* timer = [[PWDispatchTimer alloc] initWithQueue:queue];
    [timer setStartIntervalFromNow:0.02 repetitionInterval:0.04 leeway:0.01 useWallTime:NO];
    __block int32_t fireCount = 0;
    [timer enable];
    [timer setEventBlock:^{
        OSAtomicIncrement32(&fireCount);
        XCTAssertTrue(queue.isCurrentDispatchQueue);
    }];
    [NSThread sleepForTimeInterval:0.11];
    [timer cancel];
    XCTAssertEqual(fireCount, 3);
}

- (void)testDispatchTimerMultipleWithConvenienceMethod
{
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    __block int32_t fireCount = 0;
    PWDispatchTimer* timer = [PWDispatchTimer enabledTimerWithQueue:queue
                                               startIntervalFromNow:0.02
                                                 repetitionInterval:0.04
                                                             leeway:0.01
                                                        useWallTime:NO
                                                         eventBlock:^{
                                                             OSAtomicIncrement32(&fireCount);
                                                             XCTAssertTrue(queue.isCurrentDispatchQueue);
                                                         }];
    [NSThread sleepForTimeInterval:0.11];
    [timer cancel];
    XCTAssertEqual(fireCount, 3);
}

- (void)testDispatchTimerMultipleOnMainThread
{
    PWDispatchTimer* timer = [[PWDispatchTimer alloc] initWithQueue:PWDispatchQueue.mainQueue];
    [timer setStartIntervalFromNow:0.02 repetitionInterval:0.04 leeway:0.0 useWallTime:NO];
    __block NSUInteger fireCount = 0;
    [timer enable];
    [timer setEventBlock:^{
        fireCount++;
        XCTAssertTrue(PWDispatchQueue.mainQueue.isCurrentDispatchQueue);
    }];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.12]];
    [timer cancel];
    XCTAssertEqual(fireCount, 3);
}

- (void)testDispatchTimerMultipleOnMainThreadWithConvenienceMethod
{
    __block NSUInteger fireCount = 0;
    PWDispatchTimer* timer = [PWDispatchTimer enabledTimerWithQueue:PWDispatchQueue.mainQueue
                                               startIntervalFromNow:0.02
                                                 repetitionInterval:0.04
                                                             leeway:0.0
                                                        useWallTime:NO
                                                         eventBlock:^{
                                                             fireCount++;
                                                             XCTAssertTrue(PWDispatchQueue.mainQueue.isCurrentDispatchQueue);
                                                         }];
    [[NSRunLoop mainRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.12]];
    [timer cancel];
    XCTAssertEqual(fireCount, 3);
}
#endif 

- (void)testDispatchNotificationObserverAsynchronous
{
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    __block NSNotification* receivedNotification;
    PWDispatchSemaphore* semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    PWDispatchObserver* observer = [NSNotificationCenter.defaultCenter addObserverForName:@"PWDispatchTest"
                                                                                   object:self
                                                                            dispatchQueue:queue
                                                                             dispatchKind:PWDispatchQueueDispatchKindAsynchronous
                                                                               usingBlock:^(NSNotification* notification){
                                                                                   XCTAssertTrue(queue.isCurrentDispatchQueue);
                                                                                   receivedNotification = notification;
                                                                                   [semaphore signal];
                                                                               }];
    NSNotification* notification = [NSNotification notificationWithName:@"PWDispatchTest" object:self];
    [NSNotificationCenter.defaultCenter postNotification:notification];
    XCTAssertTrue([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    XCTAssertEqualObjects(notification, receivedNotification);
    [observer dispose];
}

- (void)testDispatchNotificationObserverSynchronous
{
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    __block NSNotification* receivedNotification;
    PWDispatchObserver* observer = [NSNotificationCenter.defaultCenter addObserverForName:@"PWDispatchTest"
                                                                                   object:self
                                                                            dispatchQueue:queue
                                                                             dispatchKind:PWDispatchQueueDispatchKindSynchronous
                                                                               usingBlock:^(NSNotification* notification){
                                                                                   XCTAssertTrue(queue.isCurrentDispatchQueue);
                                                                                   receivedNotification = notification;
                                                                               }];
    NSNotification* notification = [NSNotification notificationWithName:@"PWDispatchTest" object:self];
    [NSNotificationCenter.defaultCenter postNotification:notification];
    XCTAssertEqualObjects(notification, receivedNotification);
    
    [observer dispose];
    receivedNotification = nil;
    [NSNotificationCenter.defaultCenter postNotification:notification];
    XCTAssertNil(receivedNotification);
}

- (void)testDispatchNotificationObserverDynamic
{
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    __block NSNotification* receivedNotification;
    NSNotification* notification = [NSNotification notificationWithName:@"PWDispatchTest" object:self];
    __block PWDispatchSemaphore* semaphore;
    
    PWDispatchObserver* observer = [NSNotificationCenter.defaultCenter addObserverForName:@"PWDispatchTest"
                                                                                   object:self
                                                                            dispatchQueue:queue
                                                                             dispatchKind:PWDispatchQueueDispatchKindDynamic
                                                                               usingBlock:^(NSNotification* noti) {
                                                                                   XCTAssertTrue(queue.isCurrentDispatchQueue);
                                                                                   receivedNotification = noti;
                                                                                   [semaphore signal];  // message to nil on first
                                                                               }];

    // Synchronous case.
    XCTestExpectation* expectation = [self expectationWithDescription:@"notification has been received"];
    [queue asynchronouslyDispatchBlock:^{
        [NSNotificationCenter.defaultCenter postNotification:notification];
        XCTAssertEqualObjects (notification, receivedNotification);
        [expectation fulfill];
    }];
    [self waitForExpectationsWithTimeout:self.normalTimeout handler:nil];


    // Asynchronous case.
    receivedNotification = nil;
    semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    // At least one of the two semaphores needs to be ignored by the dispatch queue graph because they do form a cycle
    // together with 'queue' and the main queue. But because one is signaled before waiting for the other, nothing
    // bad happens.
    semaphore.isExcludedFromQueueGraph = YES;
    
    // Create a situation which would deadlock if the notification is sent synchronously: a block on 'queue' is waiting
    // until the main queue returns from sending the notification.
    expectation = [self expectationWithDescription:@"entererd block on queue"];
    __block PWDispatchSemaphore* semaphore2 = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    [queue asynchronouslyDispatchBlock:^{
        // I here!
        [expectation fulfill];
        // wait till notification is sent.
        [semaphore2 waitWithTimeout:self.normalTimeout useWallTime:NO];
    }];
    [self waitForExpectationsWithTimeout:self.normalTimeout handler:nil];
    
    [NSNotificationCenter.defaultCenter postNotification:notification];
    [semaphore2 signal];    // allow 'queue' to continue
    
    XCTAssertTrue ([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    XCTAssertEqualObjects (notification, receivedNotification);

    [observer dispose];
    receivedNotification = nil;
    [NSNotificationCenter.defaultCenter postNotification:notification];
    XCTAssertNil (receivedNotification);
}

- (void)testDispatchKeyValueObserverAsynchronous
{
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    __block NSDictionary* receivedChanges;
    PWDispatchSemaphore* semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    
    // Note: the observer object returned by -addObserverForKeyPaths... must stay alive for the duration of the test.
    // It does because the current autorelease pool is not drained before the test ends.
    PWDispatchObserver* observer = [dict addObserverForKeyPaths:@"test"
                                                        options:NSKeyValueObservingOptionNew  
                                                  dispatchQueue:queue
                                                  dispatchKind:PWDispatchQueueDispatchKindAsynchronous
                                                     usingBlock:^(NSString* keyPath, id obj, NSDictionary* changes){
                                                         XCTAssertTrue(queue.isCurrentDispatchQueue);
                                                         receivedChanges = changes;
                                                         [semaphore signal];
                                                     }];
    
    NSString* value = @"test";
    [dict setValue:value forKey:@"test"];
    XCTAssertTrue([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    XCTAssertEqualObjects(receivedChanges[NSKeyValueChangeNewKey], value);
    [observer dispose];
}

- (void)testDispatchKeyValueObserverSynchronous
{
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    __block NSDictionary* receivedChanges = nil;
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    PWDispatchObserver* observer = [dict addObserverForKeyPaths:@"test"
                                                        options:NSKeyValueObservingOptionNew  
                                                  dispatchQueue:queue
                                                   dispatchKind:PWDispatchQueueDispatchKindSynchronous
                                                    usingBlock:^(NSString* keyPath, id obj, NSDictionary* changes){
                                                        XCTAssertTrue(queue.isCurrentDispatchQueue);
                                                        receivedChanges = changes;
                                                    }];
    XCTAssertNotNil(observer);
    
    NSString* value = @"test";
    [dict setValue:value forKey:@"test"];
    XCTAssertEqualObjects(receivedChanges[NSKeyValueChangeNewKey], value);
    
    [observer dispose];
    receivedChanges = nil;
    [dict setValue:@"another value" forKey:@"test"];
    XCTAssertNil(receivedChanges);
}

- (void)testDispatchKeyValueObserverDynamic
{
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];

    PWDispatchQueue* syncQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"syncQueue"];
    __block NSDictionary* receivedChanges1;
    PWDispatchObserver* observer1 = [dict addObserverForKeyPaths:@"test"
                                                         options:NSKeyValueObservingOptionNew
                                                   dispatchQueue:syncQueue
                                                    dispatchKind:PWDispatchQueueDispatchKindDynamic
                                                      usingBlock:^(NSString* keyPath, id obj, NSDictionary* changes){
                                                          XCTAssertTrue(syncQueue.isCurrentDispatchQueue);
                                                          receivedChanges1 = changes;
                                                      }];
    XCTAssertNotNil(observer1);

    PWDispatchQueue* asyncQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"asyncQueue"];

    // Block asyncQueue in a block until the notification is sent.
    PWDispatchSemaphore* semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    XCTestExpectation* expectation = [self expectationWithDescription:@"is in async block"];
    [asyncQueue asynchronouslyDispatchBlock:^{
        [expectation fulfill];
        XCTAssertTrue ([semaphore waitWithTimeout:60.0 useWallTime:NO]);
    }];
    [self waitForExpectationsWithTimeout:self.shortTimeout handler:nil];

    expectation = [self expectationWithDescription:@"received async changes"];
    __block NSDictionary* receivedChanges2;
    PWDispatchObserver* observer2 = [dict addObserverForKeyPaths:@"test"
                                                         options:NSKeyValueObservingOptionNew
                                                   dispatchQueue:asyncQueue
                                                    dispatchKind:PWDispatchQueueDispatchKindDynamic
                                                      usingBlock:^(NSString* keyPath, id obj, NSDictionary* changes){
                                                          XCTAssertTrue(asyncQueue.isCurrentDispatchQueue);
                                                          receivedChanges2 = changes;
                                                          [expectation fulfill];
                                                      }];
    XCTAssertNotNil(observer2);
    

    NSString* value = @"test";
    
    [syncQueue synchronouslyDispatchBlock:^{
        [dict setValue:value forKey:@"test"];
        XCTAssertEqualObjects(receivedChanges1[NSKeyValueChangeNewKey], value);
    }];
    
    // Now allow asyncQueue to continue and receive the async notification.
    [semaphore signal];
    [self waitForExpectationsWithTimeout:self.normalTimeout handler:nil];
    XCTAssertEqualObjects(receivedChanges2[NSKeyValueChangeNewKey], value);
    
    [observer1 dispose];
    [observer2 dispose];
}

- (void)testDispatchFileObserverDelete
{
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(_cmd)];
    NSURL* URL = [NSURL fileURLWithPath:path];
    [NSFileManager.defaultManager removeItemAtURL:URL error:nil];
    NSError* error;
    XCTAssertTrue([[@"test" dataUsingEncoding:NSUTF8StringEncoding] writeToURL:URL options:0 error:&error]);
    XCTAssertEqualObjects(error, nil);
    PWDispatchFileObserver* observer = [[PWDispatchFileObserver alloc] initWithFileURL:URL
                                                                             eventMask:PWDispatchFileDelete
                                                                               onQueue:[PWDispatchQueue globalDefaultPriorityQueue]];
    XCTAssertNotNil(observer);
    PWDispatchSemaphore* semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    [observer setEventBlock:^{
        // XCTAssertTrue([PWDispatchQueue globalDefaultPriorityQueue].isCurrentDispatchQueue);
        [semaphore signal];
    }];
    [observer enable];
    [NSFileManager.defaultManager removeItemAtURL:URL error:&error];
//  STAssertEqualObjects(error, nil, nil);
//  STAssertTrue([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO], nil);  // TODO: Find a better way to test this
}

- (NSData*)testFileData
{
    static NSData* data;
    PWDispatchOnce(^{
        NSMutableString* string = [NSMutableString string];
        for(NSUInteger index=0; index<1000; index++)
            [string appendString:@"This is a testfile with many lines.\n"];
        data = [string dataUsingEncoding:NSUTF8StringEncoding];
    });
    return data;
}

- (void)testDispatchFileReader
{
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(_cmd)];
    NSURL* URL = [NSURL fileURLWithPath:path];
    [NSFileManager.defaultManager removeItemAtURL:URL error:nil];
    NSError* error;
    XCTAssertTrue([self.testFileData writeToURL:URL options:0 error:&error]);
    XCTAssertEqualObjects(error, nil);
    
    PWDispatchSemaphore* semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    NSFileHandle* handle = [NSFileHandle fileHandleForReadingFromURL:URL error:&error];
    XCTAssertEqualObjects(error, nil);
    PWDispatchFileReader* reader = [[PWDispatchFileReader alloc] initWithFileHandle:handle onQueue:queue];
    NSMutableData* readData = [NSMutableData data];
    __weak PWDispatchFileReader* weakReader = reader;
    [reader setEventBlock:^{
        XCTAssertTrue(queue.isCurrentDispatchQueue);
        PWDispatchFileReader* strongReader = weakReader;
        [readData appendData:[handle readDataOfLength:strongReader.availableBytes]];
        if(readData.length == self.testFileData.length)
            [semaphore signal];
    }];
    [reader enable];
    
    XCTAssertTrue([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    XCTAssertEqualObjects(readData, self.testFileData);
}

- (void)testDispatchFileWriter
{
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(_cmd)];
    NSURL* URL = [NSURL fileURLWithPath:path];
    NSError* error;
    [NSFileManager.defaultManager removeItemAtURL:URL error:nil];
    [[NSData data] writeToURL:URL options:0 error:&error];
    
    PWDispatchSemaphore* semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    NSFileHandle* handle = [NSFileHandle fileHandleForWritingToURL:URL error:&error];
    XCTAssertEqualObjects(error.userInfo, nil);
    PWDispatchFileWriter* writer = [[PWDispatchFileWriter alloc] initWithFileHandle:handle onQueue:queue];
    __block NSUInteger remainingLength = self.testFileData.length;
    __weak PWDispatchFileWriter* weakWriter = writer;
    [writer setEventBlock:^{
        XCTAssertTrue(queue.isCurrentDispatchQueue);
        PWDispatchFileWriter* strongWriter = weakWriter;
        NSUInteger length = MIN(strongWriter.availableBytes, remainingLength);
        [handle writeData:[self.testFileData subdataWithRange:NSMakeRange(self.testFileData.length - remainingLength, length)]];
        remainingLength -= length;
        if(!remainingLength)
        {
            [strongWriter disable];
            [semaphore signal];
        }
    }];
    [writer enable];
    
    XCTAssertTrue([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);

    NSData* writtenData = [NSData dataWithContentsOfURL:URL options:0 error:&error];
    XCTAssertEqualObjects(error, nil);
    XCTAssertEqualObjects(writtenData, self.testFileData);
}

- (void)testDispatchOnce
{
    __block NSUInteger counter = 0;
    PWDispatchGroup* group = [[PWDispatchGroup alloc] init];
    PWDispatchQueue* queue = [PWDispatchQueue globalDefaultPriorityQueue];
    for(NSUInteger index=0; index<32; index++)
        [queue asynchronouslyDispatchBlock:^{ PWDispatchOnce(^{counter++;});}  inGroup:group];
    XCTAssertTrue([group waitForCompletionWithTimeout:self.normalTimeout useWallTime:NO]);
    XCTAssertEqual(counter, 1);
}

- (void)testIORandomChannel
{
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:NSStringFromSelector(_cmd)];
    NSURL* URL = [NSURL fileURLWithPath:path];
    [NSFileManager.defaultManager removeItemAtURL:URL error:nil];
    __block BOOL didCleanUp = NO;
    PWDispatchIORandomChannel* channel = [[PWDispatchIORandomChannel alloc] initWithURL:URL
                                                                              openFlags:O_RDWR | O_CREAT
                                                                           creationMode:S_IRUSR | S_IWUSR
                                                                                  queue:PWDispatchQueue.mainQueue
                                                                         cleanupHandler:nil];
    
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    PWDispatchSemaphore* writeSemaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    NSData* data = [@"this is a test" dataUsingEncoding:NSUTF8StringEncoding];
    [channel writeData:data
    startingFromOffset:0 
                 queue:queue
               handler:^(BOOL done, NSUInteger remainingLength, NSError *errorOrNil) {
                   [writeSemaphore signal];
               }];
    XCTAssertTrue([writeSemaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    XCTAssertEqualObjects([NSData dataWithContentsOfURL:URL], data);
    
    XCTAssertFalse(didCleanUp);    
    [channel closeImmediately:NO];
    
    
    PWDispatchIORandomChannel* channel2 = [[PWDispatchIORandomChannel alloc] initWithURL:URL
                                                                               openFlags:O_RDONLY
                                                                            creationMode:0
                                                                                   queue:PWDispatchQueue.mainQueue
                                                                          cleanupHandler:nil];
    PWDispatchSemaphore* readSemaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    NSMutableData* readData = [NSMutableData data];
    [channel2 readDataStartingFromOffset:0 length:NSNotFound queue:queue handler:^(BOOL done, NSData *iData, NSError *errorOrNil) {
        [readData appendData:iData];
        if(done)
            [readSemaphore signal];
    }];
    XCTAssertTrue([readSemaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    XCTAssertEqualObjects(readData, data);
}

- (void)testIOChannelCopy
{
    NSString* sourcePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testIOChannelSource"];
    NSURL* sourceURL = [NSURL fileURLWithPath:sourcePath];
    NSString* destPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testIOChannelDestination"];
    NSURL* destURL = [NSURL fileURLWithPath:destPath];
    [NSFileManager.defaultManager removeItemAtURL:sourceURL error:nil];
    [NSFileManager.defaultManager removeItemAtURL:destURL error:nil];

    NSMutableString* sourceString = [NSMutableString string];
    for(NSUInteger index=0; index<1000; index++)
        [sourceString appendString:@"0123456789"];
    
    [sourceString writeToURL:sourceURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    
    PWDispatchIOStreamChannel* sourceChannel = [[PWDispatchIOStreamChannel alloc] initWithURL:sourceURL
                                                                                    openFlags:O_RDONLY
                                                                                 creationMode:0
                                                                                        queue:PWDispatchQueue.mainQueue
                                                                               cleanupHandler:nil];
    
    PWDispatchIOStreamChannel* destChannel = [[PWDispatchIOStreamChannel alloc] initWithURL:destURL
                                                                                  openFlags:O_RDWR | O_CREAT
                                                                               creationMode:S_IRUSR | S_IWUSR
                                                                                      queue:PWDispatchQueue.mainQueue
                                                                             cleanupHandler:nil];
    
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
 
    PWDispatchSemaphore* semaphore;
    NSString* dstString;
    
    semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    [sourceChannel copyDataWithLength:20
                     inChunksOfLength:10
                             toStream:destChannel
                                queue:queue
                      progressHandler:nil
                    completionHandler:^(NSUInteger writtenLength, NSError *errorOrNil) {
                        XCTAssertEqual(writtenLength, 20);
                        [semaphore signal];
                    }];
    XCTAssertTrue([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    dstString = [NSString stringWithContentsOfURL:destURL encoding:NSUTF8StringEncoding error:NULL];
    XCTAssertEqualObjects(dstString, @"01234567890123456789");
    
    semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    [sourceChannel copyDataWithLength:NSNotFound
                     inChunksOfLength:1234
                             toStream:destChannel
                                queue:queue
                      progressHandler:nil
                    completionHandler:^(NSUInteger writtenLength, NSError *errorOrNil) {
                        XCTAssertEqual(writtenLength, 9980);
                        [semaphore signal];
                    }];
    XCTAssertTrue([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    dstString = [NSString stringWithContentsOfURL:destURL encoding:NSUTF8StringEncoding error:NULL];
    XCTAssertEqualObjects(dstString, sourceString);
}

- (void)testIOChannelCopy2
{
    NSString* sourcePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testIOChannelSource"];
    NSURL* sourceURL = [NSURL fileURLWithPath:sourcePath];
    NSString* destPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testIOChannelDestination"];
    NSURL* destURL = [NSURL fileURLWithPath:destPath];
    [NSFileManager.defaultManager removeItemAtURL:sourceURL error:nil];
    [NSFileManager.defaultManager removeItemAtURL:destURL error:nil];
    
    NSMutableString* sourceString = [NSMutableString string];
    for(NSUInteger index=0; index<1000; index++)
        [sourceString appendString:@"0123456789"];
    
    [sourceString writeToURL:sourceURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];
    
    PWDispatchIOStreamChannel* sourceChannel = [[PWDispatchIOStreamChannel alloc] initWithURL:sourceURL
                                                                                    openFlags:O_RDONLY
                                                                                 creationMode:0
                                                                                        queue:PWDispatchQueue.mainQueue
                                                                               cleanupHandler:nil];
    
    PWDispatchIOStreamChannel* destChannel = [[PWDispatchIOStreamChannel alloc] initWithURL:destURL
                                                                                  openFlags:O_RDWR | O_CREAT
                                                                               creationMode:S_IRUSR | S_IWUSR
                                                                                      queue:PWDispatchQueue.mainQueue
                                                                             cleanupHandler:nil];
    
    PWDispatchQueue* queue = [PWDispatchQueue serialDispatchQueueWithLabel:NSStringFromSelector(_cmd)];
    
    PWDispatchSemaphore* semaphore;
    NSString* dstString;
    
    semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    [sourceChannel copyDataWithLength:NSNotFound
                     inChunksOfLength:1000
                             toStream:destChannel
                                queue:queue
                      progressHandler:nil
                    completionHandler:^(NSUInteger writtenLength, NSError *errorOrNil) {
                        XCTAssertEqual(writtenLength, 10000);
                        [semaphore signal];
                    }];
    XCTAssertTrue([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    dstString = [NSString stringWithContentsOfURL:destURL encoding:NSUTF8StringEncoding error:NULL];
    XCTAssertEqualObjects(dstString, sourceString);
}

- (void)testIOChannelCopyWithPWDispatching
{
    NSString* sourcePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testIOChannelSource"];
    NSURL* sourceURL = [NSURL fileURLWithPath:sourcePath];
    NSString* destPath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"testIOChannelDestination"];
    NSURL* destURL = [NSURL fileURLWithPath:destPath];
    [NSFileManager.defaultManager removeItemAtURL:sourceURL error:nil];
    [NSFileManager.defaultManager removeItemAtURL:destURL error:nil];
    
    NSMutableString* sourceString = [NSMutableString string];
    for(NSUInteger index=0; index<1000; index++)
        [sourceString appendString:@"0123456789"];
    
    [sourceString writeToURL:sourceURL atomically:NO encoding:NSUTF8StringEncoding error:NULL];

    id<PWDispatchQueueing> cleanupQueue = [[PWDispatchingTestImplementation alloc] init];

    PWDispatchIOStreamChannel* sourceChannel = [[PWDispatchIOStreamChannel alloc] initWithURL:sourceURL
                                                                                    openFlags:O_RDONLY
                                                                                 creationMode:0
                                                                                        queue:cleanupQueue
                                                                               cleanupHandler:^(PWDispatchIOChannel* blockChannel, NSError* errorOrNil) {
                                                                                   XCTAssertTrue (cleanupQueue.isCurrentDispatchQueue);
                                                                                   XCTAssertNil  (errorOrNil);
                                                                               }];
    
    PWDispatchIOStreamChannel* destChannel = [[PWDispatchIOStreamChannel alloc] initWithURL:destURL
                                                                                  openFlags:O_RDWR | O_CREAT
                                                                               creationMode:S_IRUSR | S_IWUSR
                                                                                      queue:cleanupQueue
                                                                             cleanupHandler:^(PWDispatchIOChannel* blockChannel, NSError* errorOrNil) {
                                                                                 XCTAssertTrue (cleanupQueue.isCurrentDispatchQueue);
                                                                                 XCTAssertNil  (errorOrNil);
                                                                             }];
    
    id<PWDispatchQueueing> queue = [[PWDispatchingTestImplementation alloc] init];
    
    PWDispatchSemaphore* semaphore;
    NSString* dstString;
    
    semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    [sourceChannel copyDataWithLength:20
                     inChunksOfLength:10
                             toStream:destChannel
                                queue:queue
                      progressHandler:nil
                    completionHandler:^(NSUInteger writtenLength, NSError *errorOrNil) {
                        XCTAssertTrue (queue.isCurrentDispatchQueue);
                        XCTAssertEqual(writtenLength, 20);
                        [semaphore signal];
                    }];
    XCTAssertTrue([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    dstString = [NSString stringWithContentsOfURL:destURL encoding:NSUTF8StringEncoding error:NULL];
    XCTAssertEqualObjects(dstString, @"01234567890123456789");
    
    semaphore = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    [sourceChannel copyDataWithLength:NSNotFound
                     inChunksOfLength:1234
                             toStream:destChannel
                                queue:queue
                      progressHandler:nil
                    completionHandler:^(NSUInteger writtenLength, NSError *errorOrNil) {
                        XCTAssertTrue (queue.isCurrentDispatchQueue);
                        XCTAssertEqual(writtenLength, 9980);
                        [semaphore signal];
                    }];
    XCTAssertTrue([semaphore waitWithTimeout:self.normalTimeout useWallTime:NO]);
    dstString = [NSString stringWithContentsOfURL:destURL encoding:NSUTF8StringEncoding error:NULL];
    XCTAssertEqualObjects(dstString, sourceString);
}

- (void)testPWDefer
{
    NSMutableArray* log = [NSMutableArray arrayWithObject:@"1"];

    // open scope
    {
        PWDefer(^{
            [log addObject:@"2"];
        });

        // inner scope
        {
            PWDefer(^{
                [log addObject:@"5"];
            });
        }
        
        // ignored scope
        if (NO)
        {
            PWDefer(^{
                [log addObject:@"6"];
            });
        }
        
        // loop scope
        // defer block will be called for each iteration
        for (NSUInteger index = 0; index < 2; index++)
        {
            PWDefer(^{
                [log addObject:@"L"];
            });
        }
        
        PWDefer(^{
            [log addObject:@"4"];
        });
        [log addObject:@"3"];
    }
    
    // note that defer blocks are being executed in reverse order.
    NSArray* expectedLog = @[@"1", @"5", @"L", @"L", @"3", @"4", @"2"];
    XCTAssertEqualObjects(log, expectedLog);
}

@end

#endif /* Availability */
