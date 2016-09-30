/*
 *  PWEnumerable.h
 *  PWFoundation
 *
 *  Created by Kai Brüning on 11.8.10.
 *  Copyright 2010 ProjectWizards. All rights reserved.
 *
 */

#import <Foundation/Foundation.h>

// Note: PWEnumerable can not adopt the NSObject protocol, because we implement it on NSObject. At this level the
// compiler does not know that NSObject (the class) supports the NSObject protocol and would complain about missing
// implementation of the NSObject protocol by NSObject (PWExtensions).

@protocol PWEnumerable < NSFastEnumeration >

@property (nonatomic, readonly) NSUInteger elementCount;

@property (nonatomic, readonly, copy) NSSet *asSet;   // may return the same set object or new one each time it is used

@end
