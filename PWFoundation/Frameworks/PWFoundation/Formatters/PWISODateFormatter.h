//
//  PWISODateFormatter.h
//  PWFoundation
//
//  Created by Kai Brüning on 7.5.10.
//
//

#import <Foundation/Foundation.h>

/*
 Format: yyyy-MM-dd[( |t|T)HH[:mm[:ss[.sss]]]]
 */

typedef enum PWISODateStyle
{
    PWISODateAndTime                    = 0,
    PWISODateOnly                       = 1,
    PWISODateAndTimeWithSecondFraction  = 2
} PWISODateStyle;

@interface PWISODateFormatter : NSFormatter

@property (nonatomic, readwrite, strong)    NSCalendar*     calendar;
@property (nonatomic, readwrite)            PWISODateStyle  style;      // default = PWISODateAndTime

// Typed variant of -stringForObjectValue:
- (NSString*) stringFromDate:(NSDate*)date;

// Variant of getObjectValue:forString:errorDescription: ignoring errors.
- (NSDate*) dateFromString:(NSString*)string;

@end
