//
//  PWWeakReferenceProxy.m
//  PWFoundation
//
//  Created by Kai Brüning on 9.11.11.
//
//

#import "PWWeakReferenceProxy.h"

@implementation PWWeakReferenceProxy

@synthesize weakReferencedObject = proxiedObject_;

- (instancetype) initWithProxiedObject:(id)proxiedObject
{
    NSParameterAssert (proxiedObject);
    if ((self = [super init]) != nil) {
        proxiedObject_ = proxiedObject;
    }
    return self;
}

- (void) dispose
{
    proxiedObject_ = nil;
}

@end
