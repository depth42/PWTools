//
//  PWDispatchQueueGraphTest.m
//  PWFoundation
//
//  Created by Kai Brüning on 2/09/15.
//
//

#import <XCTest/XCTest.h>
#import <PWFoundation/PWDispatch.h>
#import <PWFoundation/PWDispatchQueueGraph.h>

#if PWDISPATCH_USE_QUEUEGRAPH

@interface PWDispatchQueueGraphTest : XCTestCase
@end

@implementation PWDispatchQueueGraphTest

- (void) testDispatchQueueGraph
{
    [PWDispatchQueueGraph.sharedGraph reset];

    PWDispatchQueueGraphState savedState = (PWDispatchQueueGraphState) PWDispatchQueueGraphStateOption;
    // Test that "minimal" is enough to detect cycles.
    PWDispatchQueueGraphStateOption = PWDispatchQueueGraphStateMinimal;
    
    PWDispatchQueue* q1 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q1"];
    PWDispatchQueue* q2 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q2"];
    PWDispatchQueue* q3 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q3"];
    PWDispatchQueue* q4 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q4"];
    PWDispatchQueue* q5 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q5"];
    
    [q1 synchronouslyDispatchBlock:^{
        XCTAssertTrue (q1.isCurrentDispatchQueue);
        XCTAssertFalse(q2.isCurrentDispatchQueue);

        [q4 synchronouslyDispatchBlock:^{
            [q5 synchronouslyDispatchBlock:^{
            }];
        }];

        [q2 synchronouslyDispatchBlock:^{
            XCTAssertTrue (q1.isCurrentDispatchQueue);
            XCTAssertTrue (q2.isCurrentDispatchQueue);
            [q3 synchronouslyDispatchBlock:^{
                XCTAssertTrue (q1.isCurrentDispatchQueue);
                XCTAssertTrue (q2.isCurrentDispatchQueue);
                XCTAssertTrue (q3.isCurrentDispatchQueue);
            }];
        }];
        XCTAssertTrue (q1.isCurrentDispatchQueue);
        XCTAssertFalse(q2.isCurrentDispatchQueue);
    }];
    
    XCTAssertTrue ([PWDispatchQueueGraph.sharedGraph checkTreeStructure]);

    // Now create the cycle q1 -> q2 -> q3 -> q1
    [q3 synchronouslyDispatchBlock:^{
        XCTAssertTrue (q3.isCurrentDispatchQueue);
        XCTAssertFalse(q1.isCurrentDispatchQueue);
        [q1 synchronouslyDispatchBlock:^{
            XCTAssertTrue (q3.isCurrentDispatchQueue);
            XCTAssertTrue (q1.isCurrentDispatchQueue);
        }];
        XCTAssertTrue (q3.isCurrentDispatchQueue);
        XCTAssertFalse(q1.isCurrentDispatchQueue);
    }];

    XCTAssertFalse ([PWDispatchQueueGraph.sharedGraph checkTreeStructureAndLogCycles:NO]);

    PWDispatchQueueGraphStateOption = savedState;
}

- (void) testDispatchQueueGraphWithMainQueue
{
    [PWDispatchQueueGraph.sharedGraph reset];
    
    PWDispatchQueueGraphState savedState = (PWDispatchQueueGraphState) PWDispatchQueueGraphStateOption;
    PWDispatchQueueGraphStateOption = PWDispatchQueueGraphStateWithLabels;

    PWDispatchQueue* q1 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q1"];

    XCTestExpectation* expectation = [self expectationWithDescription:@"dispatch done"];
    [q1 asynchronouslyDispatchBlock:^{
        [PWDispatchQueue.mainQueue synchronouslyDispatchBlock:^{
            [expectation fulfill];
        }];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
    
    XCTAssertTrue ([PWDispatchQueueGraph.sharedGraph checkTreeStructure]);
    PWDispatchQueueGraphStateOption = savedState;
}

- (void) testCycleDetectionAfterDeadlock
{
    [PWDispatchQueueGraph.sharedGraph reset];
    
    PWDispatchQueueGraphState savedState = PWDispatchQueueGraphStateOption;
    PWDispatchQueueGraphStateOption = PWDispatchQueueGraphStateMinimal;
    
    PWDispatchQueue* queueA = [PWDispatchQueue serialDispatchQueueWithLabel:@"A"];
    PWDispatchQueue* queueB = [PWDispatchQueue serialDispatchQueueWithLabel:@"B"];
    PWDispatchGroup* group  = [[PWDispatchGroup alloc] init];

    // Create a two element deadlock cycle.
    [queueA asynchronouslyDispatchBlock:^{
        [queueB synchronouslyDispatchBlock:^{}];
    } inGroup:group];
    
    [queueB asynchronouslyDispatchBlock:^{
        [queueA synchronouslyDispatchBlock:^{}];
    } inGroup:group];
    
    // This should time out and then see the cycle in the graph.
    XCTAssertFalse ([group waitForCompletionWithTimeout:0.1 useWallTime:NO]);
    XCTAssertFalse ([PWDispatchQueueGraph.sharedGraph checkTreeStructureAndLogCycles:NO]);
    
    // Note: this test leaves two threads deadlocked for the rest of the process life.
    
    PWDispatchQueueGraphStateOption = savedState;
}

- (void) testCycleWithSemaphore
{
    [PWDispatchQueueGraph.sharedGraph reset];
    
    PWDispatchQueueGraphState savedState = (PWDispatchQueueGraphState) PWDispatchQueueGraphStateOption;
    PWDispatchQueueGraphStateOption = PWDispatchQueueGraphStateWithLabels;
    
    PWDispatchQueue* q1 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q1"];
    PWDispatchQueue* q2 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q2"];
    PWDispatchSemaphore* sem = [[PWDispatchSemaphore alloc] initWithInitialValue:0];

    XCTestExpectation* expectation = [self expectationWithDescription:@"dispatch done"];
    [q1 synchronouslyDispatchBlock:^{
        [q2 synchronouslyDispatchBlock:^{
        }];
        
        [q2 asynchronouslyDispatchBlock:^{
            [sem waitForever];
            [expectation fulfill];
        }];
        [sem signal];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];

    XCTAssertFalse ([PWDispatchQueueGraph.sharedGraph checkTreeStructureAndLogCycles:NO]);
    PWDispatchQueueGraphStateOption = savedState;
}

- (void) testSynchronoulsyUsedSemaphore
{
    [PWDispatchQueueGraph.sharedGraph reset];
    
    PWDispatchQueueGraphState savedState = (PWDispatchQueueGraphState) PWDispatchQueueGraphStateOption;
    PWDispatchQueueGraphStateOption = PWDispatchQueueGraphStateWithLabels;
    
    PWDispatchSemaphore* sem = [[PWDispatchSemaphore alloc] initWithInitialValue:0];
    
    [sem signal];
    
    [sem waitForever];
    
    XCTAssertTrue ([PWDispatchQueueGraph.sharedGraph checkTreeStructure]);
    PWDispatchQueueGraphStateOption = savedState;
}

//- (void) testArrayPerformance
//{
//    PWDispatchQueueGraphStateOption = PWDispatchQueueGraphStateWithLabels;
//    
//    PWDispatchQueue* q1 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q1"];
//    PWDispatchQueue* q2 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q2"];
//    PWDispatchQueue* q3 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q3"];
//    PWDispatchQueue* q4 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q4"];
//    
//    [self measureBlock:^{
//        
//        for (int i = 0; i < 100000; ++i) {
//            [PWDispatchQueueGraph pushInnermostCurrentDispatchQueue:q1];
//            [PWDispatchQueueGraph pushInnermostCurrentDispatchQueue:q2];
//            [PWDispatchQueueGraph pushInnermostCurrentDispatchQueue:q3];
//            [PWDispatchQueueGraph pushInnermostCurrentDispatchQueue:q4];
//            
//            [PWDispatchQueueGraph popInnermostCurrentDispatchQueue:q4];
//            [PWDispatchQueueGraph popInnermostCurrentDispatchQueue:q3];
//            
//            [PWDispatchQueueGraph pushInnermostCurrentDispatchQueue:q3];
//            [PWDispatchQueueGraph pushInnermostCurrentDispatchQueue:q4];
//            
//            [PWDispatchQueueGraph popInnermostCurrentDispatchQueue:q4];
//            [PWDispatchQueueGraph popInnermostCurrentDispatchQueue:q3];
//            [PWDispatchQueueGraph popInnermostCurrentDispatchQueue:q2];
//            [PWDispatchQueueGraph popInnermostCurrentDispatchQueue:q1];
//        }
//    }];
//}

- (void) testNodePerformance
{
    PWDispatchQueue* q1 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q1"];
    PWDispatchQueue* q2 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q2"];
    PWDispatchQueue* q3 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q3"];
    PWDispatchQueue* q4 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q4"];
    
    [self measureBlock:^{
    
        for (int i = 0; i < 100000; ++i) {
            PWCurrentDispatchQueueElement element1;
            [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element1 withDispatchQueue:q1];
            PWCurrentDispatchQueueElement element2;
            [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element2 withDispatchQueue:q2];
            PWCurrentDispatchQueueElement element3;
            [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element3 withDispatchQueue:q3];
            PWCurrentDispatchQueueElement element4;
            [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element4 withDispatchQueue:q4];
            
            [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element4];
            [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element3];
            
            [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element3 withDispatchQueue:q3];
            [PWDispatchQueueGraph pushCurrentDispatchQueueElement:&element4 withDispatchQueue:q4];
            
            [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element4];
            [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element3];
            [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element2];
            [PWDispatchQueueGraph popCurrentDispatchQueueElement:&element1];
        }
    }];
}

- (void) testGraphOverhead
{
    PWDispatchQueueGraphState savedState = PWDispatchQueueGraphStateOption;
    PWDispatchQueueGraphStateOption = PWDispatchQueueGraphStateMinimal;
    
    PWDispatchQueue* q1 = [PWDispatchQueue serialDispatchQueueWithLabel:@"q1"];
    [self measureBlock:^{
        for (int i = 0; i < 10000; ++i) {
            [q1 synchronouslyDispatchBlock:^{
            }];
        }
    }];
    
    PWDispatchQueueGraphStateOption = savedState;
}

@end

#endif
