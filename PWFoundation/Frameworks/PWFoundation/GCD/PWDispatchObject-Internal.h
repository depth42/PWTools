//
//  PWDispatchObject.h
//  PWFoundation
//
//  Created by Kai Brüning on 15.6.09.
//
//

#import "PWDispatchObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchObject ()
{
@protected
    dispatch_object_t   impl_;   // invariant and always valid
    int32_t             isDisabled_;
}

- (instancetype) initWithUnderlyingObject:(dispatch_object_t)anImpl;

@end

NS_ASSUME_NONNULL_END
