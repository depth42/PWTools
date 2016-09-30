//
//  NSTimer-PWExtensions.h
//  PWFoundation
//
//  Created by Andreas Känner on 09.03.09.
//
//

#import <Foundation/Foundation.h>


@interface NSTimer (PWExtensions)

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)ti weakTarget:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats;
+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)ti weakTarget:(id)target selector:(SEL)aSelector userInfo:(id)userInfo repeats:(BOOL)repeats;

@end
