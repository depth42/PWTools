//
//  NSMutableSet-PWExtensions.m
//  PWFoundation
//
//  Created by Torsten Radtke on 01.10.10.
//
//

#import "NSMutableSet-PWExtensions.h"

@implementation NSMutableSet (PWExtensions)

- (void)minusEnumerable:(id<PWEnumerable>)enumerable
{
    for(id object in enumerable)
        [self removeObject:object];
}

@end
