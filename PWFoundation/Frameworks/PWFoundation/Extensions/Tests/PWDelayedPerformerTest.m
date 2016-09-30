//
//  PWDelayedPerformerTest.m
//  PWFoundation
//
//  Created by Kai Brüning on 22.11.11.
//
//

#import "PWDelayedPerformerTest.h"
#import "PWDelayedPerformer.h"


@implementation PWDelayedPerformerTest

- (void) testBasics
{
    __block BOOL fired = NO;
    __unused PWDelayedPerformer* performer = [NSObject performerWithDelay:0.0 usingBlock:^{
        fired = YES;
    }];
    XCTAssertFalse (fired);

    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertTrue (fired);
    
    fired = NO;
    performer = [NSObject performerWithDelay:0.0 usingBlock:^{
        fired = YES;
    }];
    XCTAssertFalse (fired);
    
    // Check that dispose prevents the performer from firing
    [performer dispose];
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]];
    XCTAssertFalse (fired);
}

// Note: more tests could cover modes and delay

@end
