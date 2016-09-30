//
//  PWISODateFormatter.m
//  PWFoundation
//
//  Created by Kai Brüning on 7.5.10.
//
//

#import "PWISODateFormatter.h"
#import "PWDispatch.h"
#import "NSString-PWExtensions.h"

@implementation PWISODateFormatter

@synthesize calendar = calendar_;
@synthesize style    = style_;

- (NSCalendar*) calendar
{
    if (!calendar_)
        calendar_ = [NSCalendar currentCalendar];
    return calendar_;
}

+ (NSNumberFormatter*)fractionFormatter
{
    static NSNumberFormatter* formatter;
    PWDispatchOnce(^{
        formatter = [[NSNumberFormatter alloc] init];
        formatter.minimumFractionDigits = 1;
        formatter.maximumFractionDigits = 8;
        formatter.minimumIntegerDigits  = 0;
        formatter.maximumIntegerDigits  = 0;
        formatter.decimalSeparator = @".";  // just to be sure
        formatter.alwaysShowsDecimalSeparator = YES;
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];    // avoid any possible surprises
    });
    return formatter;
}

- (NSString*) stringFromDate:(NSDate*)date
{
    NSString* string;
    if (!date)
        string = @"";
    else {
        if (style_ == PWISODateOnly) {
            NSDateComponents* comps = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                                       fromDate:date];
            
            string = [NSString stringWithFormat:@"%.4li-%.2li-%.2li",(long)comps.year, (long)comps.month, (long)comps.day];
        }
        else {
            NSAssert (style_ == PWISODateAndTime || style_ == PWISODateAndTimeWithSecondFraction, nil);

            NSCalendarUnit components = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay
                                      | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
            if (style_ == PWISODateAndTimeWithSecondFraction)
                components |= NSCalendarUnitNanosecond;
            NSDateComponents* comps = [self.calendar components:components fromDate:date];

            string = [NSString stringWithFormat:@"%.04li-%.02li-%.02liT%.02li:%.02li:%.02li",
                      (long)comps.year, (long)comps.month, (long)comps.day, (long)comps.hour, (long)comps.minute, (long)comps.second];
            
            if (style_ == PWISODateAndTimeWithSecondFraction) {
                NSInteger nanoseconds = comps.nanosecond;
                if (nanoseconds > 0) {
                    double fraction = (double)nanoseconds / 1e9;
                    NSString* fractionString = [PWISODateFormatter.fractionFormatter stringFromNumber:@(fraction)];
                    string = [string stringByAppendingString:fractionString];
                }
            }
        }
    }
    return string;
}

- (NSString*) stringForObjectValue:(id)obj
{
    if (obj && ![obj isKindOfClass:NSDate.class])
        [NSException raise:NSInvalidArgumentException 
                    format:@"PWISODateFormatter can not format a %@.", NSStringFromClass ([obj class])];

    return [self stringFromDate:obj];
}

- (BOOL) getObjectValue:(id*)outValue forString:(NSString*)string errorDescription:(NSString**)outDescription
{
    NSParameterAssert (outValue);
    if(!string.length)
    {
        *outValue = nil;
        return YES;
    }
    BOOL success = NO;

    static NSRegularExpression* regEx;
    PWDispatchOnce (^{
        regEx = [NSRegularExpression
                 regularExpressionWithPattern:@"^([0-9]{1,4})-([0-9]{1,2})-([0-9]{1,2})(?:[tT\\s]\\s*([0-9]{1,2})(?::([0-9]{2})(?::([0-9]{2})(\\.[0-9]+)?)?)?)?$"
                 options:0 error:NULL];
    });
    
    NSTextCheckingResult* match = [regEx firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    if (match) {
        NSDateComponents* comps = [[NSDateComponents alloc] init];
        comps.year  = [string substringWithMatch:match rangeIndex:1].integerValue;
        comps.month = [string substringWithMatch:match rangeIndex:2].integerValue;
        comps.day   = [string substringWithMatch:match rangeIndex:3].integerValue;
        
        // For parsing there’s (so far) no difference between PWISODateAndTime and PWISODateAndTimeWithSecondFraction.
        if(style_ != PWISODateOnly) {
            NSString* aNumberString = [string substringWithMatch:match rangeIndex:4];
            if (aNumberString) {
                comps.hour = aNumberString.integerValue;
                
                aNumberString = [string substringWithMatch:match rangeIndex:5];
                if (aNumberString) {
                    comps.minute = aNumberString.integerValue;
                    
                    aNumberString = [string substringWithMatch:match rangeIndex:6];
                    if (aNumberString) {
                        comps.second = aNumberString.integerValue;
                        
                        aNumberString = [string substringWithMatch:match rangeIndex:7];
                        if (aNumberString)
                            comps.nanosecond = 1e9 * aNumberString.doubleValue;
                    }
                }
            }
        }
        *outValue = [self.calendar dateFromComponents:comps];
        success = YES;
    }
    else if (outDescription) {
        *outDescription = [NSString stringWithFormat:@"Invalid ISO date string: %@", string];
    }

    return success;
}

- (NSDate*) dateFromString:(NSString*)string
{
    NSDate* date;
    [self getObjectValue:&date forString:string errorDescription:NULL];
    return date;
}

@end
