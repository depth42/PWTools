//
//  PWDispatchFIFOBufferTest.m
//  Weblitz
//
//  Created by Frank Illenberger on 23.03.12.
//
//

#import "PWDispatchFIFOBufferTest.h"
#import "PWDispatchFIFOBuffer.h"
#import <PWFoundation/PWFoundation.h>

@implementation PWDispatchFIFOBufferTest
{
    PWDispatchFIFOBuffer* buffer_;
}

- (void)setUp
{
    [super setUp];
    buffer_ = [[PWDispatchFIFOBuffer alloc] init];
}

- (void)enqueueString:(NSString*)string
{
    NSParameterAssert(string);
    
    NSData* stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    dispatch_data_t data = [stringData newDispatchData];
    [buffer_ enqueueData:data];
}

- (NSString*)dequeueStringWithLength:(NSUInteger)desiredLength
{
    NSParameterAssert(desiredLength>0);
    
    void* buffer = malloc(desiredLength);
    NSUInteger actualLength =[buffer_ dequeueDataIntoBuffer:buffer length:desiredLength];
    if(actualLength)
    {
        NSData* data = [NSData dataWithBytesNoCopy:buffer length:actualLength freeWhenDone:YES];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    else
    {
        free(buffer);
        return nil;
    }
}

- (void)testBuffer
{
    XCTAssertNil([self dequeueStringWithLength:10]);
    [self enqueueString:@"0123"];
    XCTAssertEqualObjects([self dequeueStringWithLength:1], @"0");
    XCTAssertEqualObjects([self dequeueStringWithLength:2], @"12");
    XCTAssertEqualObjects([self dequeueStringWithLength:3], @"3");
    XCTAssertNil([self dequeueStringWithLength:10]);
    [self enqueueString:@"0123"];
    [self enqueueString:@"4567"];
    XCTAssertEqualObjects([self dequeueStringWithLength:5], @"01234");
    [self enqueueString:@"89"];
    XCTAssertEqualObjects([self dequeueStringWithLength:4], @"5678");
    [self enqueueString:@"0123"];
    XCTAssertEqualObjects([self dequeueStringWithLength:6], @"90123");
}

@end
