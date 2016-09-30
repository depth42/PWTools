//
//  NSDateFormatter-PWExtensions.h
//  PWFoundation
//
//  Created by Kai Brüning on 25.3.10.
//
//

#import <Foundation/Foundation.h>

@class PWLocality;


@interface NSDateFormatter (PWExtensions)

// Set locale, calendar and time zone of the formatter from 'locality'.
- (void) setLocality:(PWLocality*)locality;

@end
