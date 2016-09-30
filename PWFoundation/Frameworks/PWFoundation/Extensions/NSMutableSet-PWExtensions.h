//
//  NSMutableSet-PWExtensions.h
//  PWFoundation
//
//  Created by Torsten Radtke on 01.10.10.
//
//

#import <PWFoundation/PWEnumerable.h>

@interface NSMutableSet (PWExtensions)

- (void)minusEnumerable:(id<PWEnumerable>)enumerable;

@end
