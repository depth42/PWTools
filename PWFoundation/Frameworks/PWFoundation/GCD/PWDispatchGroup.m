#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5

//
//  PWDispatchGroup.m
//  PWFoundation
//
//  Created by Kai Brüning on 15.6.09.
//
//

#import "PWDispatchGroup.h"
#import "PWDispatchQueue.h"
#import "PWDispatchObject-Internal.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchGroup

- (instancetype) init
{
    dispatch_group_t newGroup = dispatch_group_create();
    if (!newGroup)
        return nil;

    return [super initWithUnderlyingObject:newGroup];
}

- (BOOL) waitForCompletionWithTimeout:(NSTimeInterval)timeout useWallTime:(BOOL)useWallTime
{
    int64_t nanoseconds = (int64_t)(timeout * (double)NSEC_PER_SEC);
    dispatch_time_t time = useWallTime ? dispatch_walltime(0, nanoseconds) : dispatch_time(0, nanoseconds);
    return dispatch_group_wait ((dispatch_group_t)impl_, time) == 0;
}

- (void) onCompletionDispatchBlock:(PWDispatchBlock)aBlock onQueue:(PWDispatchQueue*)aQueue
{
    dispatch_group_notify ((dispatch_group_t)impl_, aQueue.underlyingQueue, aBlock);
}

- (void) enter
{
    dispatch_group_enter ((dispatch_group_t)impl_);
}

- (void) leave
{
    dispatch_group_leave ((dispatch_group_t)impl_);
}

- (dispatch_group_t) underlyingGroup
{
    return (dispatch_group_t)impl_;
}

@end

#endif /* Availability */

NS_ASSUME_NONNULL_END
