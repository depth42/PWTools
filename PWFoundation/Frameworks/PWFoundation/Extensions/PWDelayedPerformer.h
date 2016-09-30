//
//  PWDelayedPerformer.h
//  PWFoundation
//
//  Created by Kai Brüning on 22.11.11.
//
//

#import "PWDispatchObject.h"

/*
 PWDelayedPerformer implements a block-based pattern for -performSelector:withObject:afterDelay:

 One advantage is that only the delayed performer instance is kept imperatively alive while the perform is pending,
 any references in the block can be weak if desired.
 */

@interface PWDelayedPerformer : NSObject

// Typically used via the NSObject categories below.
- (instancetype) initUsingBlock:(PWDispatchBlock)block afterDelay:(NSTimeInterval)delay inModes:(NSArray*)modes;
- (instancetype) initUsingBlock:(PWDispatchBlock)block order:(NSUInteger)order inModes:(NSArray*)modes;

// Fire now and stop waiting. Afterwards the performer is disposed.
- (void) performNow;

// Cancels the perform request and releases the block. Not mandatory if no reference cycles exist.
- (void) dispose;

@property (nonatomic, readonly, copy)   PWDispatchBlock block;  // nil after dispose or firing

@end

#pragma mark

@interface NSObject (PWDelayedPerformer)

// Create delayed performer with the given parameters.
// The returned object does not need to be retained, it is released automatically after the block has been called.
+ (PWDelayedPerformer*) performerWithDelay:(NSTimeInterval)delay inModes:(NSArray*)modes usingBlock:(PWDispatchBlock)block;

// Calls -performerWithDelay:inModes:usingBlock: with NSRunLoopCommonModes
+ (PWDelayedPerformer*) performerWithDelay:(NSTimeInterval)delay usingBlock:(PWDispatchBlock)block;

// Create delayed performer which uses run loop ordering parameters like NSDisplayWindowRunLoopOrdering or NSUndoCloseGroupingRunLoopOrdering
+ (PWDelayedPerformer*) performerWithOrder:(NSUInteger)order inModes:(NSArray*)modes usingBlock:(PWDispatchBlock)block;

// Calls -performerWithOrder:inModes:usingBlock: with NSRunLoopCommonModes
+ (PWDelayedPerformer*) performerWithOrder:(NSUInteger)order usingBlock:(PWDispatchBlock)block;

@end
