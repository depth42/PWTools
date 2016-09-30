//
//  PWDispatchKeyValueObserver.m
//  PWFoundation
//
//  Created by Andreas Känner on 8/11/09.
//  Copyright 2009 ProjectWizards. All rights reserved.
//

#import "PWDispatchKeyValueObserver.h"
#import "PWDispatch.h"

@implementation PWDispatchKeyValueObserver

@synthesize observerBlock   = observerBlock_;
@synthesize observedObjects = observedObjects_;
@synthesize keyPaths        = keyPaths_;

- (id)initWithDispatchQueue:(PWDispatchQueue*)queue
              observerBlock:(void (^)(NSString* keyPath, id obj, NSDictionary* change))block
                synchronous:(BOOL)isSynchronous
            observedObjects:(id <PWEnumerable>)observedObjects
                   keyPaths:(id <PWEnumerable>)keyPaths
                    options:(NSKeyValueObservingOptions)options;
{
    NSParameterAssert(queue);
    NSParameterAssert(block);
    NSParameterAssert(observedObjects.elementCount > 0);
    NSParameterAssert(keyPaths.elementCount > 0);
    if(self = [super initWithDispatchQueue:queue synchronous:isSynchronous])
    {
        observerBlock_   = [block copy];
        observedObjects_ = [(id)observedObjects respondsToSelector:@selector(copyWithZone:)] ? [(id)observedObjects copy] : observedObjects;
        keyPaths_        = [(id)keyPaths respondsToSelector:@selector(copyWithZone:)] ? [(id)keyPaths copy] : keyPaths;
        for(NSString* keyPath in keyPaths_)
            for(id observedObject in observedObjects_)
                [observedObject addObserver:self
                                 forKeyPath:keyPath
                                    options:options
                                    context:NULL];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object 
                        change:(NSDictionary*)change 
                       context:(void*)context

{
    PWDispatchBlock block = ^{ observerBlock_(keyPath, object, change); };
    if(self.synchronous)
        [self.dispatchQueue synchronouslyDispatchBlock:block];
    else 
        [self.dispatchQueue asynchronouslyDispatchBlock:block];
}

- (void)dispose
{
    if (observerBlock_) {
        for(NSString* keyPath in keyPaths_)
            for(id observedObject in observedObjects_)
                [observedObject removeObserver:self forKeyPath:keyPath];

        // Break possible reference cycles.
        observerBlock_   = nil;
        observedObjects_ = nil;
        // note: keyPaths_ are not expected to create reference cycles.
    }
    
    [super dispose];    // note: currently does nothing
}

@end
