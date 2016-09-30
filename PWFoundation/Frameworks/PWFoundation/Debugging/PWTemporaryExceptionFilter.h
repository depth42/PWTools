//
//  PWTemporaryExceptionFilter.h
//  PWFoundation
//
//  Created by Kai Brüning on 15.8.12.
//
//

#import <Foundation/Foundation.h>
#import "Intercept_objc_exception_throw.h"

@interface PWTemporaryExceptionFilter : NSObject

// Note: returns nil and does not filtering in release build.
+ (PWTemporaryExceptionFilter*) exceptionFilterWithFilterBlock:(PWExpectedExceptionFilter)filterBlock;

@property (nonatomic, readonly, strong) PWExpectedExceptionFilter   filterBlock;

// Stop filtering exceptions. Optional, automatically performed when the instance is dealloced.
- (void) dispose;

@end
