//
//  PWISOTimeFormatter.m
//  PWFoundation
//
//  Created by Frank Illenberger on 23.09.10.
//
//

#import "PWISOTimeFormatter.h"
#import "PWDispatch.h"
#import "NSString-PWExtensions.h"

@implementation PWISOTimeFormatter

- (NSString*)stringFromTime:(NSNumber*)time
{
    NSString* string;
    if(time)
    {
        NSTimeInterval interval = time.doubleValue;
        if(interval < 0.0 || interval > 24.0 * 3600.0)
            [NSException raise:NSInvalidArgumentException 
                        format:@"PWISOTimeFormatter can not format %@. Lies outside of time range 0<=time<=24.", time];
        int hour   = interval / 3600;
        int minute = (interval - ((NSTimeInterval)hour * 3600.0)) / 60.0;
        double second = interval  - ((NSTimeInterval)hour * 3600.0) - ((NSTimeInterval)minute * 60.0);
        string = [NSString stringWithFormat:@"%02d:%02d:%02g", hour, minute, second];
    }
    return string;
}

- (BOOL) getObjectValue:(id*)outValue forString:(NSString*)string errorDescription:(NSString**)outDescription
{
    NSParameterAssert (outValue);
    
    if(!string)
    {
        *outValue = nil;
        return YES;
    }
    
    BOOL success = NO;
    
    static NSRegularExpression* regEx;
    PWDispatchOnce (^{
        regEx = [NSRegularExpression
                 regularExpressionWithPattern:@"([0-9]{1,2})(?::([0-9]{2})(?::([0-9]{2})(\\.[0-9]+)?)?)"
                 options:0 error:NULL];
    });
        
    NSTextCheckingResult* match = [regEx firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    if (match) {
        int hour                = [string substringWithMatch:match rangeIndex:1].intValue;
        int minute              = [string substringWithMatch:match rangeIndex:2].intValue;
        int second              = [string substringWithMatch:match rangeIndex:3].intValue;
        NSTimeInterval fraction = [string substringWithMatch:match rangeIndex:4].doubleValue;
        NSTimeInterval time = (double)hour * 3600.0 + (double)minute * 60.0 + (double)second + fraction;
      
        if(hour >= 0 && hour <= 24 && minute >=0 && minute<60 && second>=0 && second<60 && time<=24.0*3600.0)
        {
             *outValue = @(time);
            success = YES;
        }
    }

    if (!success && outDescription)
        *outDescription = [NSString stringWithFormat:@"Invalid ISO time string: %@", string];

    return success;
}

- (NSNumber*) timeFromString:(NSString*)string
{
    NSNumber* time;
    [self getObjectValue:&time forString:string errorDescription:NULL];
    return time;
}

- (NSString*) stringForObjectValue:(id)obj
{
    if (obj && ![obj isKindOfClass:NSNumber.class])
        [NSException raise:NSInvalidArgumentException 
                    format:@"PWISOTimeFormatter can not format a %@.", NSStringFromClass ([obj class])];
    
    return [self stringFromTime:obj];
}

@end
