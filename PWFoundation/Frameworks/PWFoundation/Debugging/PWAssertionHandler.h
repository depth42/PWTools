//
//  PWAssertionHandler.h
//  PWFoundation
//
//  Created by Kai Brüning on 3.8.12.
//
//

#ifndef NDEBUG

@interface NSAssertionHandler (PWFoundation)

@property (atomic, readwrite)   BOOL    expectingAssert;    // used to disable breakpoints for unit tests

@end

// We register a custom class as the assertion handler to be able to generate exceptions of the custom
// PWAssertionException class to differentiate exceptions created by assertions from other exceptions.
@interface PWAssertionHandler : NSAssertionHandler
@end


@interface PWAssertionException : NSException

- (instancetype) initWithReason:(NSString*)reason userInfo:(NSDictionary*)userInfo;

@end

#endif
