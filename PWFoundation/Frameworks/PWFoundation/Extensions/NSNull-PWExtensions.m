//
//  NSNull-PWExtensions.m
//  PWFoundation
//
//  Created by Kai Brüning on 25.3.11.
//
//

#import "NSNull-PWExtensions.h"
#import "NSObject-PWExtensions.h"


@implementation NSNull (PWExtensions)

#pragma mark PWEnumerable

// NSNull enumerates nothing

- (NSUInteger) elementCount
{
    return 0;
}

- (NSSet*) asSet
{
    return [NSSet set];
}

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState*)state objects:(id*)stackbuf count:(NSUInteger)len
{
    return 0;   // nothing to enumerate, ever
}

@end
