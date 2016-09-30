/*
 *  PWDispatch.h
 *  PWFoundation
 *
 *  Created by Kai Brüning on 18.6.09.
 *  Copyright 2009 ProjectWizards GmbH. All rights reserved.
 *
 */

#import <PWFoundation/PWDispatchObject.h>
#import <PWFoundation/PWDispatchQueueing.h>
#import <PWFoundation/PWDispatchQueue.h>
#import <PWFoundation/PWDispatchQueueingHelper.h>
#import <PWFoundation/PWDispatchGroup.h>
#import <PWFoundation/PWDispatchTimer.h>
#import <PWFoundation/PWDispatchFileReader.h>
#import <PWFoundation/PWDispatchFileWriter.h>
#import <PWFoundation/PWDispatchFileObserver.h>
#import <PWFoundation/PWDispatchPathObserver.h>
#import <PWFoundation/PWDispatchSignalObserver.h>
#import <PWFoundation/PWDispatchProcessObserver.h>
#import <PWFoundation/PWDispatchMemoryPressureObserver.h>
#import <PWFoundation/PWDispatchSemaphore.h>
#import <PWFoundation/NSNotificationCenter-PWDispatchExtensions.h>
#import <PWFoundation/NSObject-PWDispatchExtensions.h>
#import <PWFoundation/NSData-PWDispatchExtensions.h>
#import <PWFoundation/PWDispatchObserver.h>
#import <PWFoundation/PWWeakObjectWrapper.h>
#import <PWFoundation/PWDispatchIORandomChannel.h>
#import <PWFoundation/PWDispatchIOStreamChannel.h>
#import <PWFoundation/PWDispatchFIFOBuffer.h>
#import <PWFoundation/PWKeyedBlockQueue.h>

#define PWDispatchOnce(block)                           \
do                                                      \
{                                                       \
    static dispatch_once_t dispatchOncePredicate;       \
    dispatch_once(&dispatchOncePredicate, block);       \
} while(0)


/**

 PWDefer
 Implements a swift defer alike in objective-C. Blocks declared with PWDefer are executed in reverse order, just like Swift defer statements
 
 Example Usage:

     - (void)dealWithFile
     {
         FILE *file = fopen(…);
         PWDefer(^{
             if (file)
                 fclose(file);
         });
         
         // continue code where any scope exit will
         // lead to the PWDefer block being executed
     }
 
 Source: http://nshipster.com/new-years-2016/#swift's-defer-in-objective-c
 
 */

// some helper declarations
#define _pw_macro_concat(a, b) a##b
#define pw_macro_concat(a, b) _pw_macro_concat(a, b)
NS_INLINE void pw_deferFunc(__strong PWDispatchBlock *blockRef)
{
    PWDispatchBlock actualBlock = *blockRef;
    actualBlock();
}

// the core macro
#define PWDefer(deferBlock) \
__strong PWDispatchBlock pw_macro_concat(__pw_stack_defer_block_, __LINE__) __attribute__((cleanup(pw_deferFunc), unused)) = deferBlock

// convenience dispose at end of scope, useful in tests
#define PWDeferDispose(a) PWDefer(^{ [a dispose]; });
