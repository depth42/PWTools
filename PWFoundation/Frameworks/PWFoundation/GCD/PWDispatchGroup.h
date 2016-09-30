//
//  PWDispatchGroup.h
//  PWFoundation
//
//  Created by Kai Brüning on 15.6.09.
//
//

#import "PWDispatchObject.h"

NS_ASSUME_NONNULL_BEGIN

@class PWDispatchQueue;


@interface PWDispatchGroup : PWDispatchObject

- (BOOL) waitForCompletionWithTimeout:(NSTimeInterval)timeout useWallTime:(BOOL)useWallTime;

- (void) onCompletionDispatchBlock:(PWDispatchBlock)aBlock onQueue:(PWDispatchQueue*)aQueue;

- (void) enter;

- (void) leave;

@property (nonatomic, readonly)    dispatch_group_t    underlyingGroup;

@end

NS_ASSUME_NONNULL_END
