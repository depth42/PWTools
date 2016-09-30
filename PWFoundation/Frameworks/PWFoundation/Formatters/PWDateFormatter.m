//
//  PWDateFormatter.m
//  PWFoundation
//
//  Created by Kai Brüning on 17.11.10.
//
//

#import "PWDateFormatter.h"
#import "NSString-PWExtensions.h"


@interface PWDateFormatter ()
@property (nonatomic, readwrite) BOOL isFallbackFormatter;
@end

@implementation PWDateFormatter
{
    PWDateFormatter* _shortDateFormatter;
    PWDateFormatter* _mediumDateFormatter;
    PWDateFormatter* _longDateFormatter;
    PWDateFormatter* _fullDateFormatter;
    PWDateFormatter* _shortDateShortTimeFormatter;
    PWDateFormatter* _mediumDateShortTimeFormatter;
    PWDateFormatter* _longDateShortTimeFormatter;
    PWDateFormatter* _fullDateShortTimeFormatter;
}

@synthesize allowsEmpty = allowsEmpty_;

- (BOOL) getObjectValue:(out id*)obj forString:(NSString*)string errorDescription:(out NSString**)error
{
    NSParameterAssert (obj);
    
    if (allowsEmpty_ && [string stringByTrimmingSpaces].length == 0) {
        *obj = nil;
        return YES;
    }

    if(self.isLenient && !self.isFallbackFormatter)
        return [self getObjectValueByDetectingStyle:obj forString:string errorDescription:error];
    
    return [super getObjectValue:obj forString:string errorDescription:error];
}

- (BOOL) getObjectValueByDetectingStyle:(out id*)obj forString:(NSString*)string errorDescription:(out NSString**)error
{
    NSParameterAssert (obj);
    NSAssert (self.isLenient, nil);
    
    // First try to directly get the object value:
    if([super getObjectValue:obj forString:string errorDescription:error])
        return YES;
 
    // Try to parse the string with the short date format:
    if([self.shortDateFormatter getObjectValue:obj forString:string errorDescription:error])
        return YES;

    // Medium date format:
    if([self.mediumDateFormatter getObjectValue:obj forString:string errorDescription:error])
        return YES;

    // Long date format:
    if([self.longDateFormatter getObjectValue:obj forString:string errorDescription:error])
        return YES;

    // Full date format:
    if([self.fullDateFormatter getObjectValue:obj forString:string errorDescription:error])
        return YES;

    // Short date with short time format:
    if([self.shortDateShortTimeFormatter getObjectValue:obj forString:string errorDescription:error])
        return YES;

    // Medium date with short time format:
    if([self.mediumDateShortTimeFormatter getObjectValue:obj forString:string errorDescription:error])
        return YES;

    // Long date with short time format:
    if([self.longDateShortTimeFormatter getObjectValue:obj forString:string errorDescription:error])
        return YES;

    // Full date with short time format:
    if([self.fullDateShortTimeFormatter getObjectValue:obj forString:string errorDescription:error])
        return YES;
    
    return NO;
}

- (PWDateFormatter*) shortDateFormatter
{
    if(!_shortDateFormatter)
        _shortDateFormatter = [self copyWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    return _shortDateFormatter;
}

- (PWDateFormatter*) mediumDateFormatter
{
    if(!_mediumDateFormatter)
        _mediumDateFormatter = [self copyWithDateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    return _mediumDateFormatter;
}

- (PWDateFormatter*) longDateFormatter
{
    if(!_longDateFormatter)
        _longDateFormatter = [self copyWithDateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterNoStyle];
    return _longDateFormatter;
}

- (PWDateFormatter*) fullDateFormatter
{
    if(!_fullDateFormatter)
        _fullDateFormatter = [self copyWithDateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterNoStyle];
    return _fullDateFormatter;
}

- (PWDateFormatter*) shortDateShortTimeFormatter
{
    if(!_shortDateShortTimeFormatter)
        _shortDateShortTimeFormatter = [self copyWithDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
    return _shortDateShortTimeFormatter;
}

- (PWDateFormatter*) mediumDateShortTimeFormatter
{
    if(!_mediumDateShortTimeFormatter)
        _mediumDateShortTimeFormatter = [self copyWithDateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterShortStyle];
    return _mediumDateShortTimeFormatter;
}

- (PWDateFormatter*) longDateShortTimeFormatter
{
    if(!_longDateShortTimeFormatter)
        _longDateShortTimeFormatter = [self copyWithDateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterShortStyle];
    return _longDateShortTimeFormatter;
}

- (PWDateFormatter*) fullDateShortTimeFormatter
{
    if(!_fullDateShortTimeFormatter)
        _fullDateShortTimeFormatter = [self copyWithDateStyle:NSDateFormatterFullStyle timeStyle:NSDateFormatterShortStyle];
    return _fullDateShortTimeFormatter;
}

// Creates a copy of the receiver with the given dateStyle and timeStyle.
- (PWDateFormatter*) copyWithDateStyle:(NSDateFormatterStyle)dateStyle
                             timeStyle:(NSDateFormatterStyle)timeStyle
{
    NSAssert (self.isLenient, nil);
    PWDateFormatter* formatter = [self copy];
    formatter.dateStyle = dateStyle;
    formatter.timeStyle = timeStyle;
    formatter.isFallbackFormatter = YES;
    return formatter;
}


@end
