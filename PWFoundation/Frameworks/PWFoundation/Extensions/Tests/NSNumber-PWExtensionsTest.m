//
//  NSNumber-PWExtensionsTest.m
//  PWFoundation
//
//  Created by Andreas Känner on 28.05.09.
//
//

#import "NSNumber-PWExtensionsTest.h"
#import "NSNumber-PWExtensions.h"

@implementation NSNumber_PWExtensionsTest


- (void)test
{
    NSNumber* intNumber     = [[NSNumber alloc] initWithStringRepresentation:@"0" error:NULL]; 
    NSNumber* doubleNumber  = [[NSNumber alloc] initWithStringRepresentation:@"0.5" error:NULL];
    NSNumber* boolNumber1   = [[NSNumber alloc] initWithStringRepresentation:@"y" error:NULL];
    NSNumber* boolNumber2   = [[NSNumber alloc] initWithStringRepresentation:@"t" error:NULL];
    NSNumber* boolNumber3   = [[NSNumber alloc] initWithStringRepresentation:@"n" error:NULL];
    NSNumber* boolNumber4   = [[NSNumber alloc] initWithStringRepresentation:@"f" error:NULL];             
    NSNumber* noNumber      = [[NSNumber alloc] initWithStringRepresentation:@"Steiner" error:NULL];               

    NSNumber* expectedIntNumber     = @0; 
    NSNumber* expectedDoubleNumber  = @0.5;
    NSNumber* expectedBoolNumber1_2 = @YES;
    NSNumber* expectedBoolNumber3_4 = @NO;

    XCTAssertEqualObjects(expectedIntNumber,         intNumber);
    XCTAssertEqualObjects(expectedDoubleNumber,      doubleNumber);
    XCTAssertEqualObjects(expectedBoolNumber1_2,     boolNumber1);
    XCTAssertEqualObjects(expectedBoolNumber1_2,     boolNumber2);
    XCTAssertEqualObjects(expectedBoolNumber3_4,     boolNumber3);          
    XCTAssertEqualObjects(expectedBoolNumber3_4,     boolNumber4);

    XCTAssertNil(noNumber);
}

- (void) testIsEqualFuzzy
{
    XCTAssertTrue  ([@1.0 isEqualFuzzy:@1]);
    XCTAssertTrue  ([@3.0 isEqualFuzzy:@3.000000001]);
    XCTAssertTrue  ([@3.000000001 isEqualFuzzy:@3.0]);
    XCTAssertFalse ([@3.0 isEqualFuzzy:@3.000001]);
    XCTAssertFalse ([@3.000001 isEqualFuzzy:@3.0]);

    // Check compare of integer values exceeding the precision of double.
    XCTAssertTrue  ([@NSUIntegerMax isEqualFuzzy:@NSUIntegerMax]);
    XCTAssertFalse ([@NSUIntegerMax isEqualFuzzy:@(NSUIntegerMax - 1)]);
}

@end
