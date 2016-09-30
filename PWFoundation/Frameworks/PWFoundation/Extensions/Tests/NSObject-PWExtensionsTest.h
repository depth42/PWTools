//
//  NSObject-PWExtensionsTest.h
//  PWFoundation
//
//  Created by Frank Illenberger on 15.06.10.
//
//

#import "PWTestCase.h"


@interface NSObject_PWExtensionsTest : PWTestCase
@end

@protocol TestProtocol1
@property (nonatomic, readonly) NSString* testProperty1;
@end

@protocol TestProtocol2
@property (nonatomic, readonly) NSString* testProperty2;
@end

@protocol TestProtocol3 <TestProtocol1, TestProtocol2>
@property (nonatomic, readonly) NSString* testProperty3;
@end

@interface TestClass : NSObject <TestProtocol1>
@end

@interface TestClass (TestCategory) <TestProtocol2>
@end

@interface TestClass2 : NSObject  <TestProtocol3>
@property (nonatomic, readonly) NSString* testProperty4;
@end
