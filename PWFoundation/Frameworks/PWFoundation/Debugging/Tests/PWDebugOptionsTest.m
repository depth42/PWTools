//
//  PWDebugOptionsTest.m
//  PWFoundation
//
//  Created by Kai Brüning on 26.1.10.
//
//

#import "PWDebugOptionsTest.h"
#import "PWDebugOptionMacros.h"
#import "PWLog.h"


DEBUG_OPTION_SWITCH (PWDebugOptionTestSwitch1, PWRootDebugOptionGroup,
                     @"Switch 1", @"A switch for testing",
                     DEBUG_OPTION_DEFAULT_OFF, DEBUG_OPTION_PERSISTENT)

DEBUG_OPTION_ACTIONBLOCK (PWDebugOptionTestActionBlock, PWRootDebugOptionGroup, @"Action 1",
                          @"A block-based action for testing",
                          ^(void) {
                              PWLog (@"Action 1\n");
                          })

DEBUG_OPTION_DECLARE_GROUP (TestDebugSubGroup)
DEBUG_OPTION_DEFINE_GROUP (TestDebugSubGroup, PWRootDebugOptionGroup,
                           @"Sub group 1", @"A sub group for testing")

DEBUG_OPTION_DECLARE_SWITCH (PWDebugOptionTestSwitch2)

DEBUG_OPTION_DEFINE_SWITCH (PWDebugOptionTestSwitch2, TestDebugSubGroup,
                            @"Switch 2", @"A test switch in a sub group",
                            DEBUG_OPTION_DEFAULT_OFF, DEBUG_OPTION_PERSISTENT)


typedef NS_ENUM(NSInteger, PWTestEnum) {
    PWTestValue1,
    PWTestValue2 = 10,
    PWTestValue3
};

DEBUG_OPTION_ENUM (PWDebugOptionTestEnum, PWRootDebugOptionGroup,
                   @"Test Enum", @"An enumeration option for testing", DEBUG_OPTION_ENUM_AS_SUBMENU,
                   PWTestEnum, PWTestValue2, DEBUG_OPTION_PERSISTENT,
                   @"Value 1", PWTestValue1,
                   @"Value 2", PWTestValue2,
                   @"Value 3", PWTestValue3,
                   nil)



DEBUG_OPTION_TEXT (PWDebugOptionTestText1, PWRootDebugOptionGroup,
                   @"Text 1", @"A text for testing",
                   DEBUG_OPTION_PERSISTENT)


DEBUG_OPTION_DECLARE_TEXT (PWDebugOptionTestText2)

DEBUG_OPTION_DEFINE_TEXT (PWDebugOptionTestText2, PWRootDebugOptionGroup,
                          @"Text 2", @"Another text for testing",
                          DEBUG_OPTION_PERSISTENT)



@implementation PWDebugOptionsTest

- (void) testBasicDebugOptions
{
#if HAS_DEBUG_OPTIONS
    PWRootDebugOptionGroup* rootGroup = [PWRootDebugOptionGroup createRootGroup];

    // Removed the following check because it is too volatile when new options are added to PWFoundation.
    //STAssertEquals (rootGroup.options.count, (NSUInteger)7, nil);   // includes PWLogCalculationOfDerivedPropertyWithKey
                                                          
    PWDebugOptionSubGroup* subGroup = (PWDebugOptionSubGroup*) [rootGroup optionWithTitle:@"Sub group 1"];
    XCTAssertEqual (subGroup.subGroup.options.count, (NSUInteger)1);
    
    PWDebugEnumOption* enumOption = (PWDebugEnumOption*) [rootGroup optionWithTitle:@"Test Enum"];
    XCTAssertTrue (enumOption.asSubMenu);
    XCTAssertEqual (enumOption.values.count, (NSUInteger)3);
    XCTAssertEqualObjects ((enumOption.titles)[1], @"Value 2");

    XCTAssertEqualObjects (PWDebugOptionTestText1, nil);
    PWDebugTextOption* textOption = (PWDebugTextOption*) [rootGroup optionWithTitle:@"Text 1"];
    textOption.currentValue = @"Test Text";
    XCTAssertEqualObjects (PWDebugOptionTestText1, @"Test Text");
    
#endif /* HAS_DEBUG_OPTIONS */
}

@end

