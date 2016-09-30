//
//  PWDispatchObject.h
//  PWFoundation
//
//  Created by Kai Brüning on 15.6.09.
//
//

#import <dispatch/dispatch.h>

NS_ASSUME_NONNULL_BEGIN

@class PWDispatchQueue;

typedef void(^PWDispatchBlock)(void);
typedef void(^PWApplyBlock)(size_t index);


@interface PWDispatchObject : NSObject

- (void) setFinalizerFunction:(nullable dispatch_function_t)finalizer;

// suspend and resume are balanced
- (void) suspend;   
- (void) resume;

// disable and enable are unbalanced
- (void) disable;    
- (void) enable;

@property (nonatomic, readonly)                     dispatch_object_t   underlyingObject;
@property (nonatomic, readwrite, nullable)          void*               context;
@property (nonatomic, readonly)                     BOOL                isDisabled;
@property (nonatomic, readwrite, strong, nullable)  PWDispatchQueue*    targetQueue;        // For queues and sources only.
// TODO: dispatch_debug

@end

// Conversion function from foundation dates to dispatch walltime. Mainly used internally by PWDispatch, but might be
// useful elsewhere.
dispatch_time_t PWDispatchTimeFromDate (NSDate* date);

// "transparent unions" seem to work with C-Functions only (that is not for message parameters). And type casting
// to (dispatch_object_t) no longer works with Clang in Xcode 3.2.3 (creates bogus values, looks like some kind of
// compiler bug).
// Therefore this inline function must be used to cast from an specific dispatch type (like dispatch_queue_t) to
// the generic dispatch_object_t.
// Update (Kai, 13.8.10): the bug has been fixed in Xcode 3.2.3 with IDE: 1688.0, Core: 1691.0, ToolSupport: 1591.0.
//NS_INLINE dispatch_object_t generalizeDispatchType (dispatch_object_t object)
//{
//    return object;
//}

NS_ASSUME_NONNULL_END
