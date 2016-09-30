//
//  NSObject-PWExtensionsTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 15.06.10.
//
//

#import "NSObject-PWExtensionsTest.h"
#import "NSObject-PWExtensions.h"
#import <objc/runtime.h>

@implementation TestClass
;
- (NSString*)testProperty1 { return nil; }
@end

@implementation TestClass (TestCategory)
- (NSString*)testProperty2 { return nil; }
@end

@implementation TestClass2 
;
- (NSString*)testProperty1 { return nil; }
- (NSString*)testProperty2 { return nil; }
- (NSString*)testProperty3 { return nil; }
- (NSString*)testProperty4 { return nil; }
@end

@implementation NSObject_PWExtensionsTest

- (void)testPropertyWithName
{
    Class testClass = [TestClass class];
    objc_property_t property1a = class_getProperty(testClass, "testProperty1");
    objc_property_t property2a = class_getProperty(testClass, "testProperty2");
    
    XCTAssertTrue(property1a != NULL);
    
    // Test for return of the bug reported as rdar://8093297 in LLVM or obj-c runtime
    // The Obj-C runtime did return references to properties using class_getProperty when the following conditions were met:
    // - The property was declared in a protocol
    // - The protocol was implemented in a category
    // - The program was compiled using Clang/LLVM 1.5 (Xcode 3.2.3)
    // We reported this as rdar://8093297
    // The bug was fixed with Clang/LLVM 1.6 (Xcode 3.2.5)
    XCTAssertTrue(property2a != NULL, @"Oh no, Apple let bug in rdar://8093297 return!");   
    
    // Test our method
    
    objc_property_t property1b = [testClass propertyWithName:@"testProperty1"];
    objc_property_t property2b = [testClass propertyWithName:@"testProperty2"];
    XCTAssertTrue(property1b == property1a);
    XCTAssertTrue(property2b != NULL);
}

- (void)testSupportsValueForKeyPath
{
    TestClass* obj = [[TestClass alloc] init];
    XCTAssertTrue([obj supportsValueForKeyPath:@"testProperty1"]);
    XCTAssertTrue([obj supportsValueForKeyPath:@"testProperty2"]);
    XCTAssertFalse([obj supportsValueForKeyPath:@"testProperty4"]);
    XCTAssertThrows([obj valueForKey:@"dumkey"]);
}

- (void) testIsKindOfClassProperty
{
    TestClass* obj = [[TestClass alloc] init];
    XCTAssertEqualObjects([obj valueForKey:@"isKindOfClassTestClass"], @YES);
    XCTAssertEqualObjects([obj valueForKey:@"isKindOfClassNSString"], @NO);
}

- (void)testDefinitionClassOrProtocol
{
    Class defClass;
    Protocol* defProt;
    
    [TestClass definitionClass:&defClass orProtocol:&defProt forPropertyWithName:@"testProperty1"];
    XCTAssertEqual(defClass, (Class)Nil);
    XCTAssertEqual(defProt, @protocol(TestProtocol1));

    [TestClass definitionClass:&defClass orProtocol:&defProt forPropertyWithName:@"testProperty2"];
    XCTAssertEqual(defClass, (Class)Nil);
    XCTAssertEqual(defProt, @protocol(TestProtocol2));

    [TestClass definitionClass:&defClass orProtocol:&defProt forPropertyWithName:@"testProperty3"];
    XCTAssertEqual(defClass, (Class)Nil);
    XCTAssertEqual(defProt, (Protocol*)nil);

    [TestClass2 definitionClass:&defClass orProtocol:&defProt forPropertyWithName:@"testProperty1"];
    XCTAssertEqual(defClass, (Class)Nil);
    XCTAssertEqual(defProt, @protocol(TestProtocol1));

    [TestClass2 definitionClass:&defClass orProtocol:&defProt forPropertyWithName:@"testProperty2"];
    XCTAssertEqual(defClass, (Class)Nil);
    XCTAssertEqual(defProt, @protocol(TestProtocol2));

    [TestClass2 definitionClass:&defClass orProtocol:&defProt forPropertyWithName:@"testProperty3"];
    XCTAssertEqual(defClass, (Class)Nil);
    XCTAssertEqual(defProt, @protocol(TestProtocol3));

    [TestClass2 definitionClass:&defClass orProtocol:&defProt forPropertyWithName:@"testProperty4"];
    XCTAssertEqual(defClass, TestClass2.class);
    XCTAssertEqual(defProt, (Protocol*)nil);
}

- (void)testPropertyLocalization
{
    XCTAssertEqualObjects([TestClass localizedNameForPropertyWithName:@"testProperty1" value:nil language:@"English"], @"Test prop 1 english");
    XCTAssertEqualObjects([TestClass localizedNameForPropertyWithName:@"testProperty2" value:nil language:@"English"], @"Test prop 2 english");
    XCTAssertEqualObjects([TestClass2 localizedNameForPropertyWithName:@"testProperty4" value:nil language:@"English"], @"Test prop 4 english");

    XCTAssertEqualObjects([TestClass localizedShortNameForPropertyWithName:@"testProperty1" value:nil language:@"English"], @"Test prop 1 english short");
    XCTAssertEqualObjects([TestClass localizedShortNameForPropertyWithName:@"testProperty2" value:nil language:@"English"], @"Test prop 2 english short");
    XCTAssertEqualObjects([TestClass2 localizedShortNameForPropertyWithName:@"testProperty4" value:nil language:@"English"], @"Test prop 4 english short");

    XCTAssertEqualObjects([TestClass localizedDescriptionForPropertyWithName:@"testProperty1" value:nil language:@"English"], @"Test prop 1 english description");
    XCTAssertEqualObjects([TestClass localizedDescriptionForPropertyWithName:@"testProperty2" value:nil language:@"English"], @"Test prop 2 english description");
    XCTAssertEqualObjects([TestClass2 localizedDescriptionForPropertyWithName:@"testProperty4" value:nil language:@"English"], @"Test prop 4 english description");

    XCTAssertEqualObjects([TestClass localizedNameForPropertyWithName:@"testProperty1" value:nil language:@"German"], @"Test prop 1 german");
    XCTAssertEqualObjects([TestClass localizedNameForPropertyWithName:@"testProperty2" value:nil language:@"German"], @"Test prop 2 german");
    XCTAssertEqualObjects([TestClass2 localizedNameForPropertyWithName:@"testProperty4" value:nil language:@"German"], @"Test prop 4 german");
}

- (void) testAssociatedObjects
{
    NSString* key1  = @"key1";
    NSString* key1a = @"key1a";
    NSString* key2  = @"key2";
    NSString* key2a = @"key2a";
    NSString* key3  = @"key3";
    NSString* key4  = @"key4";
    
    NSObject* referrer = [[NSObject alloc] init];
    
    // Note: we had quite some trouble to find an object which is not optimized by Foundation to a singleton or some
    // tagged pointer trick.
    // A short mutable string (Hello) did no longer work under Yosemite.
    // An empty mutable dictionary seems to be uniqued under El Capitan.
    // So this will hopefully work for a while now.
    NSMutableString* string = [[NSMutableString alloc] initWithString:@"This is a mutable test string"];
    __unsafe_unretained NSString* stringCopyPtr;

    @autoreleasepool {
        [referrer setAssociatedObject:string forKey:key1  associationPolicy:PWAssociateObjectStrong];
        // Note: atomic variants are included here for complete code coverage. No attempt is made to verify atomiticity.
        [referrer setAssociatedObject:string forKey:key1a associationPolicy:PWAssociateObjectStrongAtomic];
        [referrer setAssociatedObject:string forKey:key2  associationPolicy:PWAssociateObjectCopy];
        [referrer setAssociatedObject:string forKey:key2a associationPolicy:PWAssociateObjectCopyAtomic];

        XCTAssertEqual        ([referrer associatedObjectForKey:key1],  string);
        XCTAssertEqual        ([referrer associatedObjectForKey:key1a], string);

        NSString* stringCopy = [referrer associatedObjectForKey:key2];
        stringCopyPtr = stringCopy;
        XCTAssertTrue         (stringCopy != string);
        XCTAssertEqualObjects (stringCopy, string);

        NSString* stringCopy_a = [referrer associatedObjectForKey:key2a];
        XCTAssertTrue         (stringCopy_a != stringCopy);
        XCTAssertTrue         (stringCopy_a != string);
        XCTAssertEqualObjects (stringCopy_a, string);
        
        // Test the weak case, using the string copy created for key2.
        [referrer setAssociatedObject:stringCopy forKey:key3 associationPolicy:PWAssociateObjectWeak];
        XCTAssertEqual       ([referrer associatedObjectForKey:key3], stringCopy);
        
        // Test the unsafe unretained case, using the same copy. This reference must not keep the copy from being
        // deallocated.
        [referrer setAssociatedObject:stringCopy forKey:key4 associationPolicy:PWAssociateObjectUnsafeUnretained];

        // Remove key2, which deallocs the string copy latest when the auto release pool is flushed.
        [referrer removeAssociatedObjectForKey:key2];
        XCTAssertNil ([referrer associatedObjectForKey:key2]);
    }
    
    // Now key3 must return nil.
    XCTAssertNil ([referrer associatedObjectForKey:key3]);

    // The now deallocated pointer is still kept under key4, but any attempt to access it would crash.
    // Let’s prove that at least it can still be removed.
    [referrer removeAssociatedObjectForKey:key4];
    
    XCTAssertEqual ([referrer associatedObjectForKey:key1], string);
    [referrer removeAssociatedObjects];
    XCTAssertNil   ([referrer associatedObjectForKey:key1]);
}

@end
