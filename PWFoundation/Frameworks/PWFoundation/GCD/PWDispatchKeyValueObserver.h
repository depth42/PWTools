//
//  PWDispatchKeyValueObserver.h
//  PWFoundation
//
//  Created by Andreas Känner on 8/11/09.
//
//

#import "PWDispatchObserver.h"
#import "PWEnumerable.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^PWDispatchKeyValueObserverBlock)(NSString *_Nullable keyPath, id _Nullable obj, NSDictionary *_Nullable change);

@interface PWDispatchKeyValueObserver : PWDispatchObserver

// IMPORTANT: if a single object is to be observed which has fast-enumerable elenents, this object must be wrapped
// in a container before passing it as observedObjects.
// Note: observedObjects are remembered by the instance unretained.
- (id)initWithDispatchQueue:(id<PWDispatchQueueing>)queue
              observerBlock:(PWDispatchKeyValueObserverBlock)block
               dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
            observedObjects:(id<PWEnumerable>)observedObjects
                   keyPaths:(id<PWEnumerable>)keyPaths
                    options:(NSKeyValueObservingOptions)options;

@property (nonatomic, readonly, copy, nullable) PWDispatchKeyValueObserverBlock observerBlock;  // nil after dispose
@property (nonatomic, readonly, copy)           id <PWEnumerable>               keyPaths;

// Note: observedObjects are currently not accessible, because they are kept in a std::vector internally. An accessor
// can be added when needed, but it would have to create a new NSArray each time.

@end

NS_ASSUME_NONNULL_END
