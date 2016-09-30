//
//  PWLeakChecker.m
//  PWFoundation
//
//  Created by Frank Illenberger on 09/07/15.
//
//

#ifndef NDEBUG

#import "PWLeakChecker.h"
#import "PWDispatch.h"

@implementation PWLeakChecker
{
    NSHashTable*        _livingInstances;
    NSHashTable*        _livingInstancesToRemove;
    NSHashTable*        _expectedSurvivors;
    CFRunLoopRef        _runLoop;
    PWUInteger          _livingInstancesIterationLevel;
@package
    PWDispatchQueue*    _dispatchQueue;
}

+ (PWLeakChecker*)sharedLeakChecker
{
    static PWLeakChecker* sharedLeakChecker;
    PWDispatchOnce(^{
        sharedLeakChecker = [[PWLeakChecker alloc] init];
    });
    return sharedLeakChecker;
}

- (instancetype)init
{
    if(self = [super init])
    {
        _dispatchQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWLeakChecker"];
    }
    return self;
}

- (void) addLivingInstance:(id)instance
{
    NSParameterAssert (instance);

    [_dispatchQueue synchronouslyDispatchBlock:^{
        if(![instance isExpectedSurvivorInLeakChecker:self])
        {
            if(!_livingInstances)
                _livingInstances = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaquePersonality];
            [_livingInstances addObject:instance];
        }
    }];
}

- (void) removeLivingInstance:(__unsafe_unretained id)instance
{
    NSParameterAssert (instance);

    __block CFRunLoopRef runLoop = NULL;
    [_dispatchQueue synchronouslyDispatchBlock:^{
        [_expectedSurvivors removeObject:instance];
        [self doRemoveLivingInstance:instance];
        if(_livingInstances.count == 0 && _runLoop)
        {
            runLoop = _runLoop;
            _runLoop = NULL;
        }
    }];

    if(runLoop)
        CFRunLoopStop(runLoop);
}

- (void) doRemoveLivingInstance:(__unsafe_unretained id)instance
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);
    NSParameterAssert (instance);
    
    if (_livingInstancesIterationLevel == 0)
        [_livingInstances removeObject:instance];
    else {
        _livingInstancesToRemove = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaquePersonality];
        [_livingInstancesToRemove addObject:instance];
    }
}

- (void) resetLivingInstances
{
    [_dispatchQueue synchronouslyDispatchBlock:^{
        [_livingInstances removeAllObjects];
        // Note: _expectedSurvivors is not reset because the expectation is that such objects survive forever.
   }];
}

- (BOOL)hasLivingInstances
{
    __block CFRunLoopRef runLoop = NULL;
    __block BOOL hasLivingInstances = NO;
    [_dispatchQueue synchronouslyDispatchBlock:^{
        if (_livingInstances.count > 0) {
            // Remove any expected survivers from the living instances.
            // This is necessary because the result of -isExpectedSurvivorInLeakChecker: can change after an instance
            // has been added to _livingInstances.
            
            // Note: managed objects seem to keep objects with retain count 0 around for later dealloc (_queueForDealloc
            // can be seen in backtraces). Such objects can be seen here, therefore any retain of objects in
            // _livingInstances must be carefully avoided.

            // Added out of paranoia: in no case something should escape from here into out pools.
            @autoreleasepool {
                // Tell -removeLivingInstance: to not mutate _livingInstances synchronously. It has been seen that objects
                // were deallocated while in this loop, although at that time they were still temporarily retained.
                ++_livingInstancesIterationLevel;
                
                for (__unsafe_unretained id iInstance in _livingInstances) {
                    if ([iInstance isExpectedSurvivorInLeakChecker:self])
                        [self doRemoveLivingInstance:iInstance];
                }
                
                if (--_livingInstancesIterationLevel == 0) {
                    if (_livingInstancesToRemove) {
                        [_livingInstances minusHashTable:_livingInstancesToRemove];
                        _livingInstancesToRemove = nil;
                        if (_livingInstances.count == 0 && _runLoop) {
                            runLoop = _runLoop;
                            _runLoop = NULL;
                        }
                    }
                }
            }
            
            hasLivingInstances = _livingInstances.count > 0;
        }
    }];

    if (runLoop)
        CFRunLoopStop (runLoop);
    
    return hasLivingInstances;
}

- (void) addExpectedSurvivor:(id)instance
{
    NSParameterAssert (instance);

    [_dispatchQueue synchronouslyDispatchBlock:^{
        if(!_expectedSurvivors)
            _expectedSurvivors = [NSHashTable hashTableWithOptions:NSPointerFunctionsOpaquePersonality];
        [_expectedSurvivors addObject:instance];
        [_livingInstances removeObject:instance];
    }];
}

- (void) removeExpectedSurvivor:(__unsafe_unretained id)instance
{
    NSParameterAssert (instance);

    [_dispatchQueue synchronouslyDispatchBlock:^{
        [_expectedSurvivors removeObject:instance];
        [_livingInstances addObject:instance];
    }];
}

- (BOOL) isExpectedSurvivor:(__unsafe_unretained id)instance
{
    __block BOOL result;
    [_dispatchQueue synchronouslyDispatchBlock:^{
        result = [instance isExpectedSurvivorInLeakChecker:self];
    }];
    return result;
}

- (BOOL) directIsExpectedSurvivor:(__unsafe_unretained id)instance
{
    NSAssert(_dispatchQueue.isCurrentDispatchQueue, nil);

    return [_expectedSurvivors containsObject:instance];
}

- (void) dumpLivingInstanceClassesAndPointers
{
    [_dispatchQueue synchronouslyDispatchBlock:^{
        for(id iObj in _livingInstances)
            PWLog (@"%@<%p>\n", [iObj class], iObj);
    }];
}

- (void)dumpLivingInstances
{
    // Turns out that printing object descriptions can synchronously dispatch to other queues, therefore it must happen
    // outside of _dispatchQueue.
    // One example is NSManagedObjectContext.description, which uses -performBlockAndWait: internally if the context is
    // on a private queue.
    __block NSHashTable* livingInstances;
    [_dispatchQueue synchronouslyDispatchBlock:^{
        livingInstances = _livingInstances;
        _livingInstances = nil;
    }];
    
    if(livingInstances.count == 0)
        return;

    BOOL didDumpInstances = NO;
    for(id iClass in self.class.classDumpHierarchy)
    {
        NSUInteger leakedCount = 0;
        for(id iObj in livingInstances)
        {
            if([iObj isKindOfClass:iClass] && ![self isExpectedSurvivor:iObj])
            {
                if (!didDumpInstances)
                    PWLog (@"Leaked %@ (%p) with %li retains\n", iObj, iObj, CFGetRetainCount ((__bridge CFTypeRef) iObj));
                ++leakedCount;
            }
        }
        
        if (leakedCount > 0) {
            // We only dump instances of a single hierarchy level and just tell the count for everything else.
            if (didDumpInstances)
                PWLog (@"Leaked %lu instances of %@\n", leakedCount, iClass);
            else
                didDumpInstances = YES;
        }
    }

#if 0
    PWLogn(@"%@", livingInstances.objectEnumerator.allObjects);
#endif
    NSAssert(didDumpInstances, @"A living instance was registered whose class is not listed in classDumpHierarchyNames: %@",
             [livingInstances anyObject]);
}

- (BOOL)checkLivingInstances
{
    if(!self.hasLivingInstances)
        return YES;

    // We leniently let the run loop run for a while because some delayed actions may still retain our living instances.
    self.runLoop = CFRunLoopGetCurrent();

    CFTimeInterval interval = 0.0005;
    CFTimeInterval totalInterval = 0.0;
    while(self.hasLivingInstances && totalInterval<10.0)
    {
        // Delayed run-loop actions may autorelease objects, we want to deallocate them after running the loop,
        // therefore we wrap the run in an autorelease pool.
        @autoreleasepool {
            CFRunLoopRunInMode (kCFRunLoopDefaultMode,
                                /*seconds =*/interval,
                                /*returnAfterSourceHandled =*/NO);
        }

        totalInterval += interval; // is not an exact measure of time, but good enough
        if(interval < 0.5)
            interval *= 2;
    }
    self.runLoop = NULL;

    BOOL hasLiving = self.hasLivingInstances;
    if(hasLiving)
        [self dumpLivingInstances];

    return !hasLiving;
}

- (NSArray*)livingInstancesOfClass:(Class)aClass
{
    NSParameterAssert(aClass);

    __block NSMutableArray* result;
    [_dispatchQueue synchronouslyDispatchBlock:^{
        for(id iObj in _livingInstances)
        {
            if([iObj isKindOfClass:aClass] && ![self isExpectedSurvivor:iObj]) {
                if(!result)
                    result = [NSMutableArray array];
                [result addObject:iObj];
            }
        }
    }];
    return result;
}

+ (NSArray*)classDumpHierarchy
{
    static NSArray* classDumpHierarchy;
    PWDispatchOnce(^{
        NSMutableArray* classes = [NSMutableArray array];

        for(NSString* iString in self.classDumpHierarchyNames)
        {
            Class theClass = NSClassFromString(iString);
            // If the class does not exist, we might be running a base framework test,
            // so we simply ignore them.
            if(theClass)
                [classes addObject:theClass];
        }
        classDumpHierarchy = classes;
    });
    return classDumpHierarchy;
}

// This is the ordering in which leaked objects are dumped.
// Leaked objects with kind of class further down in the list are only
// dumped if there are no leaked objects of classes further up in the list.
// This is useful for finding the relevant leaked objects since the objects further
// up in the list commonly own the ones further down.
// We know that it is a layering violation to list classes from other frameworks here,
// but it is currently the easiest approach to get a global ordering, and it is debug-only code.
+  (NSArray*)classDumpHierarchyNames
{
    return @[@"PWPersistentDocument",
             @"PWSyncNSDocument",
             @"PWSDocument",
             @"PWWindowController",
             @"PWWindow",
             @"PWViewController",
             @"PWView",
             @"WBLApplication",
             @"WBLSession",
             @"WBLMessage",
             @"WBLComponent",
#if UXTARGET_IOS
             @"MEIPropertyObserver",
#endif
             @"MESyncClientOperation",
             @"PWSCloningBranchAccess",
             @"PWManagedObjectContext",
             @"PWManagedObject",
             @"PWPersistentStoreCoordinator",
             @"MEExporter",
             @"MEPublisher"];
}

- (void)setRunLoop:(CFRunLoopRef)loop
{
    [_dispatchQueue synchronouslyDispatchBlock:^{
        _runLoop = loop;
    }];
}

@end

#pragma mark

@implementation NSObject (PWLeakChecker)

- (BOOL)isExpectedSurvivorInLeakChecker:(PWLeakChecker*)checker
{
    // Uses "C" version of the asserts to avoid any risk of retaining self.
    NSCParameterAssert (checker);
    NSCAssert (checker->_dispatchQueue.isCurrentDispatchQueue, nil);
    
    return [checker directIsExpectedSurvivor:self];
}

@end

#endif
