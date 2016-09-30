//
//  PWDispatchKeyValueObserver.m
//  PWFoundation
//
//  Created by Andreas Känner on 8/11/09.
//
//

#import "PWDispatchKeyValueObserver.h"
#import "PWDispatchObserver-Private.h"
#import "PWDispatch.h"
#import "NSObject-PWExtensions.h"
#import "PWWeakReferenceProxy.h"
#import "PWInlineVector.hpp"

NS_ASSUME_NONNULL_BEGIN

// Observer instances need to remember the observed objects to be able to removed observation in dispose.
// It would be desirable to use weak references for this, but this wouldn’t work for self observing. An object O
// observing itself releases the observer instance in its dealloc method (with or without sending -dispose, makes no
// difference). If O would be referenced weakly by the observer instance, the weak reference is already set to nil
// when -dealloc is send to O, the observer instance would be unable to remove the observation, which results in a
// log warning from Foundation.
// For this reason the observed objects are hold unsafe_unretained, matching the pattern used by Apples for KVO.

// NSPointerArray would support unsafe_unretained, but needs ugly casting operations. And using C++ has the added
// benefit that no extra allocation is necessary for the very common single observed object case.
typedef PWFoundation::inline_vector<__unsafe_unretained id,    1> UnretainedObjects;
typedef PWFoundation::inline_vector<__unsafe_unretained Class, 1> Classes;

@implementation PWDispatchKeyValueObserver
{
    UnretainedObjects   _observedObjects;
    // The classes of the observed objects are remembered to support hunting for undisposed observers.
    Classes             _observedObjectsClasses;
#ifndef NDEBUG
    BOOL    _disposed;
#endif
}

- (id)initWithDispatchQueue:(id<PWDispatchQueueing>)queue
              observerBlock:(PWDispatchKeyValueObserverBlock)block
               dispatchKind:(PWDispatchQueueDispatchKind)dispatchKind
            observedObjects:(id <PWEnumerable>)observedObjects
                   keyPaths:(id <PWEnumerable>)keyPaths
                    options:(NSKeyValueObservingOptions)options
{
    NSParameterAssert(queue);
    NSParameterAssert(block);
    NSParameterAssert(observedObjects.elementCount > 0);
    NSParameterAssert(keyPaths.elementCount > 0);

    if(self = [super initWithDispatchQueue:queue dispatchKind:dispatchKind])
    {
        _observerBlock   = [block copy];
        _keyPaths        = [(id)keyPaths respondsToSelector:@selector(copyWithZone:)] ? [(id)keyPaths copy] : keyPaths;
        for (id iObject in observedObjects) {
            _observedObjects.push_back (iObject);
            _observedObjectsClasses.push_back ([iObject class]);
        }
        for (NSString* keyPath in keyPaths)
            for (id iObject in observedObjects)
                [iObject addObserver:self forKeyPath:keyPath options:options context:NULL];
    }
    return self;
}

- (void)observeValueForKeyPath:(nullable NSString*)keyPath
                      ofObject:(nullable id)object
                        change:(nullable NSDictionary*)change
                       context:(nullable void*)context
{
    if(!self.isDisabled)
        [self.dispatchQueue withDispatchKind:self.dispatchKind
                               dispatchBlock:^
         {
             __block PWDispatchKeyValueObserverBlock observerBlock;
             [self.internalQueue synchronouslyDispatchBlock:^{
                 observerBlock = _observerBlock;
             }];
             if(observerBlock)
                 observerBlock(keyPath, object, change);
         }];
}

- (void)dispose
{
    __block PWDispatchKeyValueObserverBlock observerBlock;
    [self.internalQueue synchronouslyDispatchBlock:^{
        observerBlock = _observerBlock; // Make sure that dealloc of observerBlock is done on the dispatch queue of the caller
        _observerBlock = nil;
    }];

    if(observerBlock)
    {
        const auto count = _observedObjects.size();
        for (auto i = 0; i < count; ++i) {
            // If accessing the object crashes because it has already been deallocated, annotate the crash report
            // with the class name and key paths. This should help to find the cause of crashes like MDEV-3011.
            // OPT: unfortunately the cost for building the note text has to be paid for each dispose.
            Class iClass = _observedObjectsClasses[i];
            PWNoteInCrashReportForPerformingBlock ([NSString stringWithFormat:@"removing observer from a %@ for %@",
                                                    iClass, _keyPaths],
                                                   ^{
                                                       id object = _observedObjects[i];
                                                       // Classes of the observed objects are asserted against the
                                                       // original classes. This detects cases in which the observed
                                                       // object has been deallocated in the meantime and at the same
                                                       // memory location an new object of a different class has been
                                                       // allocated. Not bullet proof, but may be helpful. Note that the
                                                       // observed object itself can be a class (e.g. for the publisher
                                                       // type chooser).
                                                       NSAssert ([object isKindOfClass:iClass] || [object isSubclassOfClass:iClass],
                                                                 @"Observed object class changed, probably a newly allocated object at the same address");
                                                       
                                                       for (NSString* keyPath in _keyPaths)
                                                           [object removeObserver:self forKeyPath:keyPath];
                                                   });
        }
    }
    
    [super dispose];

#ifndef NDEBUG
    _disposed = YES;
#endif
}

@end

NS_ASSUME_NONNULL_END
