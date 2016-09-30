//
//  PWDispatchMainQueueTimer.h
//  PWFoundation
//
//  Created by Torsten Radtke on 05.12.13.
//
//

/*
 The PWDispatchMainQueueTimer solves the issue of starving (and delayed) timer events for NSTimer (introduced in 10.9)
 caused by user initiated NSEvents in the run loop. By using another queue for the timer and calling back into the main 
 thread, the event block is called on a regular basis even if many NSEvents are processed.
 */

#import "PWDispatchTimer.h"

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchMainQueueTimer : PWDispatchTimer

@end

NS_ASSUME_NONNULL_END
