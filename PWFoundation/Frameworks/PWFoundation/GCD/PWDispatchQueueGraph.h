//
//  PWDispatchQueueGraph.h
//  PWFoundation
//
//  Created by Kai Brüning on 1/09/15.
//
//

#import <PWFoundation/PWDispatchQueue.h>    // for PWDISPATCH_USE_QUEUEGRAPH
#import <PWFoundation/PWDispatchSemaphore.h>
#import <PWFoundation/PWDebugOptionMacros.h>

#if PWDISPATCH_USE_QUEUEGRAPH

NS_ASSUME_NONNULL_BEGIN

@protocol PWDispatchQueueing;

@protocol PWDispatchQueueGraphLabeling < NSObject >
@property (nonatomic, readonly, copy, nullable) NSString*   dispatchQueueLabel;
@end

// Note: tried to convert this to C++ leveraging RAII and inlining, but this was surprisingly a little slower than the
// method based version. May change when optimized, but this code is only of interest in develop builds.
typedef struct PWCurrentDispatchQueueElement {
    __unsafe_unretained id<PWDispatchQueueing>      queue_;
    struct PWCurrentDispatchQueueElement *_Nullable nextElement_;
} PWCurrentDispatchQueueElement;

@interface PWDispatchQueueGraph : NSObject

+ (PWDispatchQueueGraph*) sharedGraph;

+ (void) pushCurrentDispatchQueueElement:(PWCurrentDispatchQueueElement*)outNode
                       withDispatchQueue:(id<PWDispatchQueueing>)dispatchQueue;
+ (void) popCurrentDispatchQueueElement:(PWCurrentDispatchQueueElement*)inNode;
+ (nullable id<PWDispatchQueueing, PWDispatchQueueGraphLabeling>) innermostCurrentDispatchQueue;

+ (void) dumpCurrentDispatchQueues;

- (void) addSynchronousDispatchToQueue:(id<PWDispatchQueueGraphLabeling>)dispatchObject;

- (void) addSynchronousDispatchFromQueue:(id<PWDispatchQueueGraphLabeling>)sourceObject
                                 toQueue:(id<PWDispatchQueueGraphLabeling>)targetObject;

// Must be called when an object which may have been passed to -addSynchronousDispatchToQueue: or
// -addSynchronousDispatchFromQueue:toQueue: is deallocated.
- (void) removeDispatchObject:(id)dispatchObject;

- (BOOL) checkTreeStructureAndLogCycles:(BOOL)logCycles;

@property (nonatomic, readonly) BOOL checkTreeStructure;    // convenience with logCycles == YES

// Resets the whole graph. Must be called on the main thread. Mainly meant for tests.
- (void) reset;

@end

@interface PWDispatchQueue (PWDispatchQueueGraph) < PWDispatchQueueGraphLabeling >
@end

@interface PWDispatchSemaphore (PWDispatchQueueGraph) < PWDispatchQueueGraphLabeling >
@end

// The performance impact increases with higher states.
typedef NS_ENUM (NSInteger, PWDispatchQueueGraphState)
{
    PWDispatchQueueGraphStateOff,
    PWDispatchQueueGraphStateMinimal,
    PWDispatchQueueGraphStateWithLabels,
    PWDispatchQueueGraphStateWithBacktrace
};

DEBUG_OPTION_DECLARE_ENUM_D (PWDispatchQueueGraphStateOption, NSInteger, PWDispatchQueueGraphStateOff)

NS_ASSUME_NONNULL_END

#endif
