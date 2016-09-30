//
//  PWEnumFormatterTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 03.03.10.
//
//

#import "PWEnumFormatterTest.h"
#import "PWEnumFormatter.h"
#import "PWLocality.h"

@implementation PWEnumFormatterTest

// Starting with iOS9/OS X 10.11 SDK, passing nil to stringForObjectValue: creates a compiler warning.
// We regard this as an error in the SDK and filed a radar on it. In the meantime, we silence the warning.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"

- (void)testEnglish
{
    NSNumber* valA = @1;
    NSNumber* valB = @2;
    PWEnumFormatter* formatter = [[PWEnumFormatter alloc] initWithLocality:[[PWLocality alloc] initWithLocale:nil language:@"English"]
                                                                    bundle:[NSBundle bundleForClass:self.class]
                                                                    values:@[valA, valB]
                                                          unlocalizedNames:@[@"valueA", @"valueB"]
                                                   unlocalizedNilValueName:@"nada"
                                                     localizationKeyPrefix:nil];
    
    XCTAssertEqualObjects([formatter stringForObjectValue:valA], @"Value A");
    XCTAssertEqualObjects([formatter stringForObjectValue:valB], @"Value B");
    XCTAssertEqualObjects([formatter stringForObjectValue:nil], @"Nada");
    
    NSNumber* value;
    BOOL success;
 
    success = [formatter getObjectValue:&value forString:@"Value A" errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(value, valA);

    success = [formatter getObjectValue:&value forString:@"valueA" errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(value, valA);

    success = [formatter getObjectValue:&value forString:@"Value B" errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(value, valB);
 
    success = [formatter getObjectValue:&value forString:@"" errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertNil(value);

    success = [formatter getObjectValue:&value forString:nil errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertNil(value);

    success = [formatter getObjectValue:&value forString:@"Nada" errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertNil(value);

    success = [formatter getObjectValue:&value forString:@"nada" errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertNil(value);

    success = [formatter getObjectValue:&value forString:@"dum" errorDescription:nil];
    XCTAssertFalse(success);
}

- (void)testGerman
{
    NSNumber* valA = @1;
    NSNumber* valB = @2;
    PWEnumFormatter* formatter = [[PWEnumFormatter alloc] initWithLocality:[[PWLocality alloc] initWithLocale:nil language:@"German"]
                                                                    bundle:[NSBundle bundleForClass:self.class]
                                                                    values:@[valA, valB]
                                                          unlocalizedNames:@[@"valueA", @"valueB"]
                                                   unlocalizedNilValueName:nil
                                                     localizationKeyPrefix:@"prefix_"];
    
    XCTAssertEqualObjects([formatter stringForObjectValue:valA], @"Wert A");
    XCTAssertEqualObjects([formatter stringForObjectValue:valB], @"Wert B");
    XCTAssertEqualObjects([formatter stringForObjectValue:nil], @"");
    
    NSNumber* value;
    BOOL success;
    
    success = [formatter getObjectValue:&value forString:@"Wert A" errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(value, valA);

    success = [formatter getObjectValue:&value forString:@"valueA" errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(value, valA);

    success = [formatter getObjectValue:&value forString:@"Wert B" errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(value, valB);
    
    success = [formatter getObjectValue:&value forString:@"" errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertNil(value);
    
    success = [formatter getObjectValue:&value forString:nil errorDescription:nil];
    XCTAssertTrue(success);
    XCTAssertNil(value);
    
    success = [formatter getObjectValue:&value forString:@"dum" errorDescription:nil];
    XCTAssertFalse(success);
}

#pragma clang diagnostic pop

@end
