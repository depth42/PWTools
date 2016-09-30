//
//  PWNumberWithUnitFormatter.m
//  PWFoundation
//
//  Created by Torsten Radtke on 24.03.11.
//
//

#import "PWNumberWithUnitFormatter.h"

@implementation PWNumberWithUnitFormatter

@synthesize unit    = unit_;
@synthesize factor  = factor_;

#pragma mark Managing life cycle

- (void)setup
{
    self.formatterBehavior = NSNumberFormatterBehavior10_4;
    self.numberStyle = NSNumberFormatterDecimalStyle;
#if UXTARGET_OSX
    self.localizesFormat = YES;
#else
    // Note:    that on iOS the default locale is the currentLocale
    //          and therefore the formatter is localized.
    NSAssert(self.locale == [NSLocale currentLocale], nil);
    // PWASSERT_NOT_AVAILABLE_IOS;
#endif
    
    [self setUnit:@"" factor:1.0];    
}

- (instancetype)init
{
	if(self = [super init])
	{
        [self setup];
	}
    
	return self;
}

#if UXTARGET_OSX
- (void)awakeFromNib
{
    PWASSERT_NOT_AVAILABLE_OSX; // layering violation against Appkit
//    [super awakeFromNib];
    [self setup];
}
#endif

#pragma mark Setting unit and factor

- (void)setUnit:(NSString*)unit factor:(double)factor
{
    NSParameterAssert(unit);
    NSParameterAssert(factor != 0.0);
    
    unit_   = [unit copy];
    factor_ = factor;
}

#pragma mark Converting between string and object value

- (NSString*)stringForObjectValue:(id)object
{
    // Map nil and empty strings to empty string. Needed in MEPageDistributionAccessoryView to ensure that a nil value
    // for a disabled field is never translated to "0 <unit>" even if the formatter is bound to the text field
    // after the binding already fired during nib loading.
    if (!object || [object isEqual:@""])
        return @"";
    
    NSString* objectString = [super stringForObjectValue:@([object doubleValue]*factor_)];
	return [objectString stringByAppendingFormat:@" %@", unit_];
}

- (BOOL)getObjectValue:(id*)object forString:(NSString*)string errorDescription:(NSString**)error
{
    BOOL result = NO;
    
    string = [string stringByReplacingOccurrencesOfString:unit_ withString:@""];
	if([super getObjectValue:object forString:string errorDescription:error])
	{	 
		*object = @([*object doubleValue]/factor_);
		result = YES;
	}
    
	return result;
}

@end
