//
//  NSDateFormatter-PWExtensions.m
//  PWFoundation
//
//  Created by Kai Brüning on 25.3.10.
//
//

#import "NSDateFormatter-PWExtensions.h"
#import "PWLocality.h"


@implementation NSDateFormatter (PWExtensions)

- (void) setLocality:(PWLocality*)locality
{
    self.locale   = locality.locale;
    self.calendar = locality.calendar;
    // Note: NSDateFormatter seems to ignore the time zone of the calendar. At least it prooves necessary to
    // set the time zone directly here (Kai, 25.3.10).
    self.timeZone = locality.calendar.timeZone;
}

@end
