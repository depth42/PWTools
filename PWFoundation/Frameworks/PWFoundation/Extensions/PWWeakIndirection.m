//
//  PWWeakIndirection.m
//  PWFoundation
//
//  Created by Kai Brüning on 26.6.13.
//
//

#import "PWWeakIndirection.h"
#import "PWAsserts.h"

@implementation PWWeakIndirection

- (instancetype) initWithIndirectedObject:(id)indirectedObject
{
    if ((self = [super init]) != nil) {
        // Added to hunt MDEV-3038.
        PWReleaseAssert (![indirectedObject isKindOfClass:PWWeakIndirection.class],
                         @"Trying to weakly indirect weak indirection <%p> with <%p>", indirectedObject, self);
        _pw_indirectedObject = indirectedObject;
    }
    return self;
}

@synthesize pw_indirectedObject = _pw_indirectedObject;

- (id) pw_indirectedObject
{
    id pw_indirectedObject = _pw_indirectedObject;
    // Added to hunt MDEV-3038.
    PWReleaseAssert (![pw_indirectedObject isKindOfClass:PWWeakIndirection.class],
                     @"Weak indirection <%p> points to weak indirection <%p>", self, pw_indirectedObject);
    return pw_indirectedObject;
}

@end

#pragma mark

@implementation NSObject (PWWeakIndirection)

- (id) pw_indirectedObject
{
    return self;
}

@end
