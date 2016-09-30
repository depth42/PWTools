//
//  PWDispatchQueueingHelperTest.m
//  PWFoundation
//
//  Created by Kai Brüning on 2/09/15.
//
//

#import <PWFoundation/PWDispatch.h>
#import "PWTestCase.h"

@interface PWDispatchQueueingHelperTest : PWTestCase
@end

@interface ReleaseTestObject : NSObject
- (instancetype) initWithDeallocHook:(PWDispatchBlock)deallocHook;
- (void) doNothing;
@end

@implementation PWDispatchQueueingHelperTest

- (void) testAsynchronousBlockRelease
{
    PWDispatchQueueingHelper* helper = [[PWDispatchQueueingHelper alloc] init];
    
    PWDispatchBlock wrapper;
    
    @autoreleasepool {
        ReleaseTestObject* testObject = [[ReleaseTestObject alloc] initWithDeallocHook:^{
            XCTAssertTrue (helper.isCurrentDispatchQueue);
        }];
        
        PWDispatchBlock block = ^{
            [testObject doNothing];
        };

        __block PWDispatchBlock originalBlock = [block copy];
        
        wrapper = ^{
            [helper callAsynchronouslyDispatchedBlock:&originalBlock];
        };
    }
    
    wrapper();
}

@end

@implementation ReleaseTestObject
{
    PWDispatchBlock _deallocHook;
}
- (instancetype) initWithDeallocHook:(PWDispatchBlock)deallocHook
{
    _deallocHook = deallocHook;
    return self;
}

- (void) doNothing
{
}

- (void) dealloc
{
    if (_deallocHook)
        _deallocHook();
}

@end
