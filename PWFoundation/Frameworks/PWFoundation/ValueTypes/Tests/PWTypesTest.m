//
//  PWTypesTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 11.06.13.
//
//

#import "PWTypesTest.h"
#import "PWTypes.h"

typedef NSObjectBehaviour CFMutableStringRef    PWCFMutableStringObject;

@implementation PWTypesTest

- (void)testCFAutorelease
{
    CFMutableStringRef autoreleasedString;
    CFMutableStringRef ARCedStringOutside;
    @autoreleasepool {
        autoreleasedString = [self provideAutoreleasedString];
        PWCFMutableStringObject ARCedString = [self provideARCedString];
        
        XCTAssertEqual(CFGetRetainCount(autoreleasedString), (CFIndex)1);
        XCTAssertTrue(CFGetRetainCount(ARCedString) >= (CFIndex)1); // works with both Xcode 4 and 5

        CFRetain(autoreleasedString);
        XCTAssertEqual(CFGetRetainCount(autoreleasedString), (CFIndex)2);

        CFRetain(ARCedString);
        XCTAssertTrue(CFGetRetainCount(ARCedString) >= (CFIndex)2); // works with both Xcode 4 and 5
        ARCedStringOutside = ARCedString;
    }
    XCTAssertEqual(CFGetRetainCount(autoreleasedString), (CFIndex)1);
    CFRelease(autoreleasedString);

    XCTAssertEqual(CFGetRetainCount(ARCedStringOutside), (CFIndex)1);
    CFRelease(ARCedStringOutside);
}

- (CFMutableStringRef)provideAutoreleasedString
{
    CFMutableStringRef string = CFStringCreateMutable(NULL, 0);
    return CFAutoRelease (CFMutableStringRef, string);
}

- (PWCFMutableStringObject)provideARCedString
{
    CFMutableStringRef string = CFStringCreateMutable(NULL, 0);
    return CFTransferToARC (PWCFMutableStringObject, string);
}

@end
