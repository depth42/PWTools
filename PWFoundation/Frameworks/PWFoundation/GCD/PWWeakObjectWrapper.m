//
//  PWWeakObjectWrapper.m
//  PWFoundation
//
//  Created by Frank Illenberger on 07.09.10.
//
//

#import "PWWeakObjectWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWWeakObjectWrapper

@synthesize object = object_;

- (instancetype)initWithObject:(id)object
{
    if(self = [self init])
    {
        object_ = object;
    }
    return self;
}

@end

NS_ASSUME_NONNULL_END
