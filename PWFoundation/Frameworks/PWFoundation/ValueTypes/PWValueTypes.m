//
//  PWValueTypes.m
//  PWFoundation
//
//  Created by Frank Illenberger on 25.11.10.
//
//

#import "PWValueTypes.h"
#import "PWDispatch.h"
#import "PWLocality.h"
#import "NSObject-PWExtensions.h"
#import "NSArray-PWExtensions.h"
#import "NSBundle-PWExtensions.h"
#import "NSString-PWExtensions.h"
#import "PWBoolFormatter.h"
#import "PWEnumFormatter.h"
#import "PWFallbackFormatter.h"
#import "PWNumberFormatter.h"
#import "PWCurrencyFormatter.h"
#import "PWBlockFormatter.h"
#import "PWDateFormatter.h"
#import "PWISODateFormatter.h"
#import "PWISOTimeFormatter.h"
#import "PWErrors.h"
#import "NSCalendar-PWExtensions.h"
#import "NSDateFormatter-PWExtensions.h"
#import "PWBlockFormatter.h"
#import "PWValueGroup.h"

#if UXTARGET_IOS
#import <MobileCoreServices/MobileCoreServices.h>
#endif

#pragma mark - Double

@implementation PWDoubleValueType

- (instancetype)initWithFallbackKeyPath:(NSString*)fallbackKeyPath 
            presetValuesBlock:(PWPresetValuesBlock)block
                      minimum:(NSNumber*)minimum
                      maximum:(NSNumber*)maximum
                        steps:(NSNumber*)steps
{
    if(self = [super initWithFallbackKeyPath:fallbackKeyPath presetValuesBlock:block])
    {
        _minimum  = [minimum copy];
        _maximum  = [maximum copy];
        _steps    = [steps copy];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithFallbackKeyPath:nil 
                       presetValuesBlock:nil
                                 minimum:nil
                                 maximum:nil
                                   steps:nil];
}


- (Class)valueClass
{
    return NSNumber.class;
}

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    NSNumberFormatter* formatter = [[PWNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.lenient = YES;
    formatter.locale = context.locality.locale;
    if([options[PWValueTypeFormatterForImportExportKey] boolValue])
    {
        formatter.maximumFractionDigits = 50;
        formatter.minimumFractionDigits = 0;
#if UXTARGET_OSX
        formatter.hasThousandSeparators = NO;   // about to become deprectated by usesGroupingSeparator
#endif
        formatter.usesGroupingSeparator = NO;
    }
    else
    {
        NSString* numberOfDecimals = options[PWNumberOfDecimalsFormatKey];
        NSString* trailingZeros    = options[PWTrailingZerosFormatKey];
        formatter.maximumFractionDigits = numberOfDecimals ? numberOfDecimals.integerValue : 50;
        formatter.minimumFractionDigits = [trailingZeros isEqual:PWTrailingZerosShow] ? formatter.maximumFractionDigits : 0;
        if([options[PWZerosFormatKey] isEqual:PWZerosHide])
            formatter.zeroSymbol = @"";
    }
    return formatter;
}

- (id<NSCopying>)formatterCacheKeyForContext:(id<PWValueTypeContext>)context
                                     options:(NSDictionary*)options
                                      object:(id)object
                                     keyPath:(NSString*)keyPath
{
    return @[self.class,
             options ? [options copy]: NSNull.null];
}

- (BOOL)value:(id*)outValue
      context:(id <PWValueTypeContext>)targetContext
       object:(id)targetObject
    fromValue:(id)value
     withType:(PWValueType*)type
      context:(id <PWValueTypeContext>)sourceContext
       object:(id)sourceObject
        error:(NSError**)outError
{
    NSParameterAssert(outValue);
    NSParameterAssert(type);
    
    BOOL success;
    if([type isKindOfClass:PWDoubleValueType.class])
    {
        *outValue = value;
        success = YES;
    }
    else
        success = [super value:outValue 
                       context:targetContext
                        object:targetObject
                     fromValue:value
                      withType:type 
                       context:sourceContext
                        object:sourceObject
                         error:outError];
    return success;
}

- (NSArray*)formatOptionKeys
{
    NSMutableArray* keys = [NSMutableArray arrayWithObjects:PWNumberOfDecimalsFormatKey, PWTrailingZerosFormatKey, PWZerosFormatKey, nil];
    [keys addObjectsFromArray:super.formatOptionKeys];
    return keys;
}

- (NSString*)formatOptionLocalizationPrefix
{
    return @"valueType.double.formatOption.";
}

- (PWValueType*)valueTypeForFormatterOptionWithKey:(NSString*)key
{
    NSParameterAssert(key);
    if([key isEqual:PWNumberOfDecimalsFormatKey])
        return PWNumberOfDecimalsValueType.valueType;
    if([key isEqual:PWTrailingZerosFormatKey])
        return PWTrailingZerosValueType.valueType;
    else if([key isEqual:PWZerosFormatKey])
        return PWZerosValueType.valueType;
    else
        return [super valueTypeForFormatterOptionWithKey:key];
}

NSString* const PWNumberOfDecimalsFormatKey = @"numberOfDecimals";
NSString* const PWTrailingZerosFormatKey    = @"trailingZeros";
NSString* const PWTrailingZerosShow         = @"show";
NSString* const PWTrailingZerosHide         = @"hide";
NSString* const PWZerosFormatKey            = @"zeros";
NSString* const PWZerosHide                 = @"hide";

- (NSArray*)typicalValuesInContext:(id <PWValueTypeContext>)context
{
    return @[@(3.56)];
}

- (double)numberForValue:(id)value
     referenceRangeStart:(id)referenceStartValue
                     end:(id)referenceEndValue
                 context:(id <PWValueTypeContext>)context
{
    return value ? ((NSNumber*)value).doubleValue : NAN;
}

- (id)valueForNumber:(double)number
 referenceRangeStart:(id)referenceStartValue
                 end:(id)referenceEndValue
             context:(id <PWValueTypeContext>)context
{
    return isnan(number) ? nil : @(number);
}
@end

#pragma mark -

@implementation PWNumberOfDecimalsValueType

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
    if(outValues)
        *outValues = [PWValueGroup groupWithValues:@[@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8"]];
    return PWValueTypeForcesPresetValues | PWValueTypeNilIsPresetValue;
}

- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context
{
    PWValueGroup* values;
    [self presetValuesModeForContext:context object:nil options:nil values:&values];
    return values.deepValues;
}

- (NSString*)unlocalizedNilValueNameForContext:(id <PWValueTypeContext>)context
{
    return @"unlimited";
}

- (NSString*)localizationKeyPrefixForContext:(id <PWValueTypeContext>)context
{
    return @"valueType.double.formatOption.numberOfDecimals.";
}

@end

#pragma mark -

@implementation PWTrailingZerosValueType

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
    if(outValues)
        *outValues = [PWValueGroup groupWithValues:@[PWTrailingZerosShow, PWTrailingZerosHide]];
    return PWValueTypeForcesPresetValues | PWValueTypeNilIsPresetValue;
}

- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context
{
    PWValueGroup* values;
    [self presetValuesModeForContext:context object:nil options:nil values:&values];
    return values.deepValues;
}

- (NSString*)unlocalizedNilValueNameForContext:(id <PWValueTypeContext>)context
{
    return @"automatic";
}

- (NSString*)localizationKeyPrefixForContext:(id <PWValueTypeContext>)context
{
    return @"valueType.double.formatOption.trailingZeros.";
}
@end

#pragma mark -

@implementation PWZerosValueType

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                   values:(PWValueGroup**)outValues
{
    if(outValues)
        *outValues = [PWValueGroup groupWithValues:@[PWZerosHide]];
    return PWValueTypeForcesPresetValues | PWValueTypeNilIsPresetValue;
}

- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context
{
    PWValueGroup* values;
    [self presetValuesModeForContext:context object:nil options:nil values:&values];
    return values.deepValues;
}

- (NSString*)unlocalizedNilValueNameForContext:(id <PWValueTypeContext>)context
{
    return @"show";
}

- (NSString*)localizationKeyPrefixForContext:(id <PWValueTypeContext>)context
{
    return @"valueType.double.formatOption.zeros.";
}
@end

#pragma mark - Integer

@implementation PWIntegerValueType

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    PWNumberFormatter* formatter = (PWNumberFormatter*)[super directFormatterForContext:context options:options object:object keyPath:keyPath];
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = 0;
    return formatter;
}

- (BOOL)value:(id*)outValue
      context:(id <PWValueTypeContext>)targetContext
       object:(id)targetObject
    fromValue:(id)value
     withType:(PWValueType*)type
      context:(id <PWValueTypeContext>)sourceContext
       object:(id)sourceObject
        error:(NSError**)outError;
{
    NSParameterAssert(outValue);
    NSParameterAssert(type);
    BOOL success;
    if([type isKindOfClass:PWDoubleValueType.class])
    {
        *outValue = value ? @([value integerValue]) : nil;
        success = YES;
    }
    else
        success = [super value:outValue 
                       context:targetContext
                        object:targetObject
                     fromValue:value
                      withType:type 
                       context:sourceContext
                        object:sourceObject
                         error:outError];
    return success;
}

- (NSArray*)typicalValuesInContext:(id <PWValueTypeContext>)context
{
    return @[@1000];
}

// Override from PWDoubleValueType
- (NSArray*)formatOptionKeys
{
    return nil;
}
@end

#pragma mark - Percent

@implementation PWPercentValueType

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    PWNumberFormatter* formatter = (PWNumberFormatter*)[super directFormatterForContext:context options:options object:object keyPath:keyPath];
    formatter.numberStyle = NSNumberFormatterPercentStyle;
    // By default, liit precision to 2 digits if not exporting
    if(!options[PWNumberOfDecimalsFormatKey] && ![options[PWValueTypeFormatterForImportExportKey] boolValue])
    {
        formatter.maximumFractionDigits = 2;
        formatter.minimumFractionDigits = 0;
    }
    return formatter;
}

- (NSArray*) formatterOptionsForDescendingWidths
{
    static NSArray* optionsArray;
    PWDispatchOnce (^{
        optionsArray = (@[
                        @{PWTrailingZerosFormatKey: PWTrailingZerosShow},
                        @{PWTrailingZerosFormatKey: PWTrailingZerosHide}
                        ]);
    });
    return optionsArray;
}

- (NSDictionary*)formatterOptions:(NSDictionary*)options appendWithDescendingWidths:(NSDictionary*)other
{
    NSString* formatKey = PWTrailingZerosFormatKey;
    static NSArray* formatsOrdered;
    PWDispatchOnce(^{
        formatsOrdered = [self.formatterOptionsForDescendingWidths map:^id(NSDictionary* option) { return option[formatKey]; }];
    });
    
    return [self.class formatterOptions:options
             appendWithDescendingWidths:other
                         formatsOrdered:formatsOrdered
                              formatKey:formatKey];
}

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
    if(outValues)
    {
        static PWValueGroup* values;
        if(!values)
        {
            values = [[PWValueGroup alloc] init];
            NSUInteger count = 4;
            double step = 1.0 / (double)count;
            for(NSUInteger index=0; index<=count; index++)
                [values addValue:@(((double)index)*step)];
            [values makeImmutable];
        }
        *outValues = values;
    }
    
    return PWValueTypeAllowsPresetValues;
}

@end

#pragma mark - Currency

@implementation PWCurrencyValueType

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    BOOL isImport = [options[PWValueTypeFormatterForImportExportKey] boolValue];
    PWCurrencyFormatter* formatter = [[PWCurrencyFormatter alloc] initWithLocality:context.locality
                                                                        hideZeroes:!isImport && [options[PWZerosFormatKey] isEqual:PWZerosHide]];

    if(isImport)
    {
        // maximum accuracy for export
        formatter.maximumFractionDigits = 50;
        formatter.minimumFractionDigits = 0;
    }
    return formatter;
}

- (id<NSCopying>)formatterCacheKeyForContext:(id<PWValueTypeContext>)context
                                     options:(NSDictionary*)options
                                      object:(id)object
                                     keyPath:(NSString*)keyPath
{
    return @[self.class,
             options ? [options copy] : NSNull.null];
}

// Override from base class
- (BOOL)isNegativeCurrencyValue:(id)value
{
    return ((NSNumber*)value).doubleValue < 0.0;
}

@end

#pragma mark - Bool

NSString* const PWBoolFormatterShowsYesNo = @"PWBoolFormatterShowsYesNo";

@implementation PWBoolValueType

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    PWBoolFormatter* formatter = [[PWBoolFormatter alloc] init];
    formatter.showsYesAndNo = options && [options[PWBoolFormatterShowsYesNo] boolValue];
    formatter.locality = context.locality;
    return formatter;
}

- (BOOL)value:(id*)outValue
      context:(id <PWValueTypeContext>)targetContext
       object:(id)targetObject
    fromValue:(id)value
     withType:(PWValueType*)type
      context:(id <PWValueTypeContext>)sourceContext
       object:(id)sourceObject
        error:(NSError**)outError;
{
    NSParameterAssert(outValue);
    NSParameterAssert(type);

    BOOL success;
    if(type.valueClass == self.valueClass)
    {
        *outValue = value ? @([value boolValue]) : nil;
        success = YES;
    }
    else
        success = [super value:outValue 
                       context:targetContext
                        object:targetObject
                     fromValue:value
                      withType:type 
                       context:sourceContext
                        object:sourceObject
                         error:outError];
    return success;
}

// Override from PWDoubleValueType
- (NSArray*)formatOptionKeys
{
    return nil;
}

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
    if(outValues)
        *outValues = [PWValueGroup groupWithValues:@[@NO, @YES]];
    return PWValueTypeForcesPresetValues | PWValueTypeNilIsPresetValue;
}

- (NSArray*)typicalValuesInContext:(id <PWValueTypeContext>)context
{
    return @[@YES, @NO];
}

@end

#pragma mark -

@implementation PWMixedBoolValueType

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    PWBoolFormatter* formatter = (PWBoolFormatter*)[super directFormatterForContext:context options:options object:object keyPath:keyPath];
    formatter.allowsMixed = YES;
    return formatter;
}

- (BOOL)value:(id*)outValue
      context:(id <PWValueTypeContext>)targetContext
       object:(id)targetObject
    fromValue:(id)value
     withType:(PWValueType*)type
      context:(id <PWValueTypeContext>)sourceContext
       object:(id)sourceObject
        error:(NSError**)outError
{
    NSParameterAssert(outValue);
    NSParameterAssert(type);

    BOOL success;
    if(type.valueClass == self.valueClass && [value intValue] == -1)
    {
        *outValue = @(PWBoolMixed);
        success = YES;
    }
    else
        success = [super value:outValue 
                       context:targetContext
                        object:targetObject
                     fromValue:value
                      withType:type 
                       context:sourceContext
                        object:sourceObject
                         error:outError];
    return success;
}

@end

#pragma mark - Date

@implementation PWDateTimeValueType

- (Class)valueClass
{
    return NSDate.class;
}

- (NSDictionary*)preferredFormatterOptions
{
    return @{PWDateFormatKey: PWDateFormatMedium,
             PWTimeFormatKey: PWTimeFormatWithoutTime};
}

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    NSFormatter* formatter;
    PWLocality* locality = context.locality;
    
    if ([options[PWValueTypeFormatterForImportExportKey] boolValue]) {
        // Use the ISO date formatter for importing and exporting of dates.
        PWISODateFormatter* isoFormatter = [[PWISODateFormatter alloc] init];
        isoFormatter.calendar = locality.calendar;
        isoFormatter.style = PWISODateAndTime;
        formatter = isoFormatter;
    } 
    else {
        PWDateFormatter* dateFormatter = [[PWDateFormatter alloc] init];
        dateFormatter.allowsEmpty = YES;
        [dateFormatter setLenient:YES];
        
        NSDateFormatterStyle dateStyle;
        NSDateFormatterStyle timeStyle;
        NSString* dateFormat = options[PWDateFormatKey];
        NSString* timeFormat = options[PWTimeFormatKey];
        
        if([dateFormat isEqualToString:PWDateFormatLong])
            dateStyle = NSDateFormatterLongStyle;
        else if([dateFormat isEqualToString:PWDateFormatShort])
            dateStyle = NSDateFormatterShortStyle;
        else if([dateFormat isEqualToString:PWDateFormatNone])
            dateStyle = NSDateFormatterNoStyle;
        else
            dateStyle = NSDateFormatterMediumStyle;
 
        if([timeFormat isEqualToString:PWTimeFormatWithoutTime])
            timeStyle = NSDateFormatterNoStyle;
        else
            timeStyle = NSDateFormatterShortStyle;
        
        dateFormatter.dateStyle = dateStyle;
        dateFormatter.timeStyle = timeStyle;
        [dateFormatter setLocality:locality];   // our extension, sets locale, calendar and timeZone
//        dateFormatter.locale    = locality.locale;
//        dateFormatter.calendar  = locality.calendar;
//        dateFormatter.timeZone  = locality.calendar.timeZone;
        formatter = dateFormatter;
    }
    return formatter;
}

- (id<NSCopying>)formatterCacheKeyForContext:(id<PWValueTypeContext>)context
                                     options:(NSDictionary*)options
                                      object:(id)object
                                     keyPath:(NSString*)keyPath
{
    return @[self.class,
             options ? [options copy]: NSNull.null];
}

- (NSArray*)formatOptionKeys
{
    NSMutableArray* keys = [NSMutableArray arrayWithObjects:PWDateFormatKey, PWTimeFormatKey, nil];
    [keys addObjectsFromArray:super.formatOptionKeys];
    return keys;
}

- (PWValueType*)valueTypeForFormatterOptionWithKey:(NSString*)key
{
    NSParameterAssert(key);
    if([key isEqual:PWDateFormatKey])
        return PWDateFormatValueType.valueType;
    else if([key isEqual:PWTimeFormatKey])
        return PWTimeFormatValueType.valueType;
    else
        return [super valueTypeForFormatterOptionWithKey:key];
}

NSString* const PWDateFormatKey         = @"dateFormat";
NSString* const PWDateFormatShort       = @"short";
NSString* const PWDateFormatMedium      = @"medium";
NSString* const PWDateFormatLong        = @"long";
NSString* const PWDateFormatNone        = @"none";

NSString* const PWTimeFormatKey         = @"timeFormat";
NSString* const PWTimeFormatWithoutTime = @"withoutTime";
NSString* const PWTimeFormatWithTime    = @"withTime";

- (NSArray*) formatterOptionsForDescendingWidths
{
    static NSArray* optionsArray;
    PWDispatchOnce (^{
        NSDictionary* longDateWithTimeFormatOption      = (@{PWDateFormatKey: PWDateFormatLong,
                                                           PWTimeFormatKey: PWTimeFormatWithTime});
        NSDictionary* mediumDateWithTimeFormatOption    = (@{PWDateFormatKey: PWDateFormatMedium,
                                                           PWTimeFormatKey: PWTimeFormatWithTime});
        NSDictionary* shortDateWithTimeFormatOption     = (@{PWDateFormatKey: PWDateFormatShort,
                                                           PWTimeFormatKey: PWTimeFormatWithTime});
        NSDictionary* longDateWithoutTimeFormatOption   = (@{PWDateFormatKey: PWDateFormatLong,
                                                           PWTimeFormatKey: PWTimeFormatWithoutTime});
        NSDictionary* mediumDateWithoutTimeFormatOption = (@{PWDateFormatKey: PWDateFormatMedium,
                                                           PWTimeFormatKey: PWTimeFormatWithoutTime});
        NSDictionary* shortDateWithoutTimeFormatOption  = (@{PWDateFormatKey: PWDateFormatShort,
                                                           PWTimeFormatKey: PWTimeFormatWithoutTime});
        optionsArray = (@[longDateWithTimeFormatOption,
                        mediumDateWithTimeFormatOption,
                        shortDateWithTimeFormatOption,
                        longDateWithoutTimeFormatOption,
                        mediumDateWithoutTimeFormatOption,
                        shortDateWithoutTimeFormatOption]);
    });
    return optionsArray;
}

- (NSDictionary*)formatterOptions:(NSDictionary*)options appendWithDescendingWidths:(NSDictionary*)other
{
    // setup ordering, note that PWDateFormatValueType keys are not ordered in descending width
    static NSArray* dateFormatsOrdered;
    static NSArray* timeFormatsOrdered;
    PWDispatchOnce(^{
        dateFormatsOrdered = (@[PWDateFormatLong, PWDateFormatMedium, PWDateFormatShort, PWDateFormatNone]);
        timeFormatsOrdered = (@[PWTimeFormatWithTime, PWTimeFormatWithoutTime]);
    });
    
    BOOL didChange = NO;
    NSDictionary* dateMerged = [PWValueType formatterOptions:options
                                  appendWithDescendingWidths:other
                                              formatsOrdered:dateFormatsOrdered
                                                   formatKey:PWDateFormatKey];
    didChange |= dateMerged != options;

    NSDictionary* timeMerged = [PWValueType formatterOptions:options
                                  appendWithDescendingWidths:other
                                              formatsOrdered:timeFormatsOrdered
                                                   formatKey:PWTimeFormatKey];
    didChange |= timeMerged != options;

    if (didChange)
    {
        NSMutableDictionary* result = [NSMutableDictionary dictionary];
        [result addEntriesFromDictionary:options];
        result[PWDateFormatKey] = dateMerged[PWDateFormatKey];
        result[PWTimeFormatKey] = timeMerged[PWTimeFormatKey];
        return [result copy];
    }
    
    return options;
}

- (BOOL)value:(id*)outValue
      context:(id <PWValueTypeContext>)targetContext
       object:(id)targetObject
    fromValue:(id)value
     withType:(PWValueType*)type
      context:(id <PWValueTypeContext>)sourceContext
       object:(id)sourceObject
        error:(NSError**)outError;
{
    NSParameterAssert(outValue);
    NSParameterAssert(type);
    BOOL success;
    if([type isKindOfClass:PWDateTimeValueType.class])
    {
        *outValue = value;
        success = YES;
    }
    else
        success = [super value:outValue 
                       context:targetContext
                        object:targetObject
                     fromValue:value
                      withType:type 
                       context:sourceContext
                        object:sourceObject
                         error:outError];
    return success;
}

- (NSArray*)typicalValuesInContext:(id <PWValueTypeContext>)context
{
    // December 21th, 2001, 1:08 - Day and month with two digits, to have it as wide as possible for formatters that
    // return a numerical string, also used a month with rather wide characters.
    
    return @[[NSDate dateWithTimeIntervalSinceReferenceDate:3600.0 * 24.0 * 354.0 + 68.5]];
}

- (double)numberForValue:(id)value
     referenceRangeStart:(id)referenceStartValue
                     end:(id)referenceEndValue
                 context:(id <PWValueTypeContext>)context
{
    NSDate* date = value;
    return date ? date.timeIntervalSinceReferenceDate : NAN;
}

- (id)valueForNumber:(double)number
 referenceRangeStart:(id)referenceStartValue
                 end:(id)referenceEndValue
             context:(id <PWValueTypeContext>)context
{
    return isnan(number) ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:number];
}

- (NSString*)formatOptionLocalizationPrefix
{
    return @"valueType.dateTime.formatOption.";
}

- (NSString*)localizedFixingStringForContext:(id<PWValueTypeContext>)context
{
    return nil;
}

- (NSString*)localizedGeneralFixingStringForContext:(id<PWValueTypeContext>)context
{
    return nil;
}

- (NSBundle*)localizationBundle
{
    // Make sure subclasses in other bundles use the localizations in this bundle.
    return [NSBundle bundleForClass:PWDateTimeValueType.class];
}

@end

#pragma mark -

@implementation PWDateFormatValueType

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
    if(outValues)
        *outValues = [PWValueGroup groupWithValues:@[PWDateFormatShort, PWDateFormatMedium, PWDateFormatLong, PWDateFormatNone]];
    return PWValueTypeForcesPresetValues | PWValueTypeNilIsPresetValue;
}

- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context
{
    return @[PWDateFormatShort, PWDateFormatMedium, PWDateFormatLong, PWDateFormatNone];
}

- (NSString*)unlocalizedNilValueNameForContext:(id <PWValueTypeContext>)context
{
    return @"automatic";
}

- (NSString*)localizationKeyPrefixForContext:(id <PWValueTypeContext>)context
{
    return @"valueType.dateTime.formatOption.dateFormat.";
}
@end

#pragma mark -

@implementation PWTimeFormatValueType

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
   if(outValues)
        *outValues = [PWValueGroup groupWithValues:@[PWTimeFormatWithoutTime, PWTimeFormatWithTime]];
    return PWValueTypeForcesPresetValues | PWValueTypeNilIsPresetValue;
}

- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context
{
    return @[PWTimeFormatWithoutTime, PWTimeFormatWithTime];
}

- (NSString*)unlocalizedNilValueNameForContext:(id <PWValueTypeContext>)context
{
    return @"automatic";
}

- (NSString*)localizationKeyPrefixForContext:(id <PWValueTypeContext>)context
{
    return @"valueType.dateTime.formatOption.timeFormat.";
}
@end

#pragma mark -

@implementation PWDateValueType

- (NSDictionary*)preferredFormatterOptions
{
    return @{PWDateFormatKey: PWDateFormatMedium,
             PWTimeFormatKey: PWTimeFormatWithoutTime};
}

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    NSFormatter* formatter;
    if ([options[PWValueTypeFormatterForImportExportKey] boolValue]) {
        // Use the ISO date formatter for importing and exporting of dates.
        PWISODateFormatter* isoFormatter = [[PWISODateFormatter alloc] init];
        isoFormatter.calendar = context.locality.calendar;
        isoFormatter.style = PWISODateOnly;
        formatter = isoFormatter;
    } else {
        PWDateFormatter* dateFormatter = [[PWDateFormatter alloc] init];
        dateFormatter.allowsEmpty = YES;
        [dateFormatter setLenient:YES];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        [dateFormatter setLocality:context.locality];   // our extension, sets locale, calendar and timeZone
//        dateFormatter.locale = context.locality.locale;
        formatter = dateFormatter;
    }
    return formatter;
}

@end

#pragma mark -

@implementation PWTimeValueType

- (Class)valueClass
{
    return NSNumber.class;
}

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    if ([options[PWValueTypeFormatterForImportExportKey] boolValue])
        return [[PWISOTimeFormatter alloc] init];

    PWBlockFormatter* formatter = [[PWBlockFormatter alloc] init];
    PWDateFormatter* dateFormatter = [[PWDateFormatter alloc] init];
    dateFormatter.allowsEmpty = YES;
    [dateFormatter setLenient:YES];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;
    dateFormatter.locale = context.locality.locale;
    dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    dateFormatter.calendar = [NSCalendar GMTCalendar];
    
    formatter.toStringBlock = ^(PWBlockFormatter* blockFormatter, id value) {
        NSTimeInterval interval = [value doubleValue];
        NSDate* date = [NSDate dateWithTimeIntervalSinceReferenceDate:interval];
        return [dateFormatter stringForObjectValue:date];
    };

    formatter.toObjectValueBlock = ^BOOL(PWBlockFormatter* blockFormatter, id* outValue, NSString* string, NSString** outErrorString) {
        NSDate* date;
        BOOL success = [dateFormatter getObjectValue:&date forString:string errorDescription:outErrorString];
        if(success)
        {
            NSDateComponents* components = [[NSCalendar GMTCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond fromDate:date];
            *outValue = @(components.hour * SECONDS_PER_HOUR + components.minute * SECONDS_PER_MINUTE + components.second);
        }
        return success;
    };
    return formatter;
}

@end

#pragma mark -

@implementation PWDurationUnitValueType

- (instancetype)initWithUsesPluralForm:(BOOL)usesPluralForm
              includesNoUnit:(BOOL)includesNoUnit
{
    if(self = [super init])
    {
        _usesPluralForm = usesPluralForm;
        _includesNoUnit = includesNoUnit;
    }
    return self;
}

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
    if(outValues)
    {
        if(_includesNoUnit)
            *outValues = [PWValueGroup groupWithValues:
                          @[@(PWDurationNoUnit),
                           @(PWDurationSeconds),
                           @(PWDurationMinutes),
                           @(PWDurationHours),
                           @(PWDurationDays),
                           @(PWDurationWeeks),
                           @(PWDurationMonths),
                           @(PWDurationQuarters),
                           @(PWDurationYears)]];
        else
            *outValues = [PWValueGroup groupWithValues:
                          @[@(PWDurationSeconds),
                           @(PWDurationMinutes),
                           @(PWDurationHours),
                           @(PWDurationDays),
                           @(PWDurationWeeks),
                           @(PWDurationMonths),
                           @(PWDurationQuarters),
                           @(PWDurationYears)]];
    }
    return PWValueTypeForcesPresetValues;
}

- (NSArray*) unlocalizedValueNamesForContext:(id<PWValueTypeContext>)context
{
    NSMutableArray* names = [NSMutableArray array];
    if(_includesNoUnit)
        [names addObject:@"none"];
    if(_usesPluralForm)
        [names addObjectsFromArray:@[@"seconds", @"minutes", @"hours", @"days", @"weeks", @"months", @"quarters", @"years"]];
    else
        [names addObjectsFromArray:@[@"second", @"minute", @"hour", @"day", @"week", @"month", @"quarter", @"year"]];
    return names;
}

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    PWEnumFormatter* formatter = (PWEnumFormatter*)[super directFormatterForContext:context options:options object:object keyPath:keyPath];
    
    // Localizations in the DurationUnits table are for use in numbers so we
    // have to capizalize the first letter for stand-alone use
    // But don’t do this if not localization is done anyway.
    if (![context.locality.language isEqual:PWLanguageNonLocalized])
        formatter.capitalizesFirstCharacter = ![options[PWValueTypeFormatterForImportExportKey] boolValue];
    return formatter;
}

- (id<NSCopying>)formatterCacheKeyForContext:(id<PWValueTypeContext>)context
                                     options:(NSDictionary*)options
                                      object:(id)object
                                     keyPath:(NSString*)keyPath
{
    return @[self.class,
             options ? [options copy] : NSNull.null,
             @(_usesPluralForm),
             @(_includesNoUnit)];
}

- (NSString*)localizationKeyPrefixForContext:(id <PWValueTypeContext>)context
{
    return @"valueType.durationUnit.";
}

@end


#pragma mark - String

@implementation PWStringValueType

- (Class)valueClass
{
    return NSString.class;
}

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    static PWBlockFormatter* formatter;
    PWDispatchOnce(^{
        formatter = [[PWBlockFormatter alloc] init];
        formatter.toStringBlock = ^(PWBlockFormatter* blockFormatter, id value) {
            return (NSString*)value; 
        };
        formatter.toObjectValueBlock = ^(PWBlockFormatter* blockFormatter, id* value, NSString* string, NSString** error) {
            *value = string;
            return YES;
        };
    });
    return formatter;
}

- (BOOL)value:(id*)outValue
      context:(id <PWValueTypeContext>)targetContext
       object:(id)targetObject
    fromValue:(id)value
     withType:(PWValueType*)type
      context:(id <PWValueTypeContext>)sourceContext
       object:(id)sourceObject
        error:(NSError**)outError
{
    if(!type)
    {
        if(outValue)
            *outValue = [value description];
        return YES;
    }
    else
        return [super value:outValue
                    context:targetContext
                     object:targetObject
                  fromValue:value withType:type
                    context:sourceContext
                     object:sourceObject
                      error:outError];
}

- (NSArray*)typicalValuesInContext:(id <PWValueTypeContext>)context
{
    return @[@"Typical String"];
}

@end

#pragma mark -

@implementation PWStringEncodingValueType

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                   values:(PWValueGroup**)outValues
{
    if(outValues)
        *outValues = [PWValueGroup groupWithValues:
                      @[@(NSMacOSRomanStringEncoding),
                      @(NSISOLatin1StringEncoding), 
                      @(NSISOLatin2StringEncoding), 
                      @(NSWindowsCP1252StringEncoding),   // windows latin 1
                      @(NSWindowsCP1250StringEncoding),   // windows latin 2
                      @(NSUTF8StringEncoding), 
                      @(NSUTF16StringEncoding)]];
    return PWValueTypeForcesPresetValues;
}

- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context
{
    return @[@"macintosh",
            @"iso-8859-1",
            @"iso-8859-2",
            @"windows-1252",
            @"windows-1250",
            @"utf-8",
            @"utf-16"];
}

- (NSString*)localizationKeyPrefixForContext:(id <PWValueTypeContext>)context
{
    return @"valueType.stringEncoding.";
}
@end

#pragma mark -

@implementation PWURLStringValueType

- (NSArray*)typicalValuesInContext:(id <PWValueTypeContext>)context
{
    return @[@"http://www.apple.com"];
}

@end

#pragma mark -

@implementation PWURLValueType
- (Class)valueClass
{
    return NSURL.class;
}

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    static PWBlockFormatter* formatter;
    PWDispatchOnce(^{
        formatter = [[PWBlockFormatter alloc] init];
        formatter.toStringBlock = ^(PWBlockFormatter* blockFormatter, id value) {
            return ((NSURL*)value).description; 
        };
        formatter.toObjectValueBlock = ^(PWBlockFormatter* blockFormatter, id* value, NSString* string, NSString** error) {
            *value = string ? [NSURL URLWithString:string] : nil;
            return YES;
        };
    });
    return formatter;
}

@end


#pragma mark - Attributed String

@implementation PWAttributedStringValueType

- (Class)valueClass
{
    return NSAttributedString.class;
}

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    static PWBlockFormatter* formatter;
    PWDispatchOnce(^{
        formatter = [[PWBlockFormatter alloc] init];
        formatter.toStringBlock = ^(PWBlockFormatter* blockFormatter, id value) {
            return ((NSAttributedString*)value).string; 
        };
        formatter.toObjectValueBlock = ^(PWBlockFormatter* blockFormatter, id* value, NSString* string, NSString** error) { 
            *value = string ? [[NSAttributedString alloc] initWithString:string] : nil;
            return YES;
        };
    });
    return formatter;
}

- (NSArray*)typicalValuesInContext:(id <PWValueTypeContext>)context
{
    static NSArray* values;
    PWDispatchOnce(^{
        values = @[[[NSAttributedString alloc] initWithString:@"A Typical String."]];
    });
    return values;
}

@end

#pragma mark -

@implementation PWFullAttributedStringValueType 
@end

#pragma mark -

@implementation PWLongFullAttributedStringValueType
@end

#pragma mark - Data

@implementation PWDataValueType
- (Class)valueClass
{
    return NSData.class;
}
@end

#pragma mark - Enum

@implementation PWEnumValueType 

- (Class)valueClass
{
    return NSNumber.class;
}

- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context
{
    return nil;
}

- (NSString*)unlocalizedNilValueNameForContext:(id <PWValueTypeContext>)context
{
    return nil;
}

- (NSString*)localizationKeyPrefixForContext:(id <PWValueTypeContext>)context
{
    return nil;
}

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    PWValueGroup* values;
    PWValueTypePresetValuesMode mode = [self presetValuesModeForContext:context object:object options:options values:&values];
    if(mode != PWValueTypeNoPresetValues)
    {
        NSArray* names = [self unlocalizedValueNamesForContext:context];
        NSString* nilName = [self unlocalizedNilValueNameForContext:context];
        NSString* prefix = [self localizationKeyPrefixForContext:context];

        NSString* language = context.locality.language;
        PWLocalizer* localizer = language && ![language isEqualToString:PWLanguageNonLocalized] ? [self localizerForContext:context] : nil;
        return [[PWEnumFormatter alloc] initWithLocalizer:localizer
                                                   values:values.deepValues
                                         unlocalizedNames:names
                                  unlocalizedNilValueName:nilName
                                    localizationKeyPrefix:prefix];
    }
    else
        return nil;
}

- (NSString*)unlocalizedNameForValue:(id)value
                             context:(id <PWValueTypeContext>)context
                              object:(id)object 
                             options:(NSDictionary*)options
{
    if(!value)
        return [self unlocalizedNilValueNameForContext:context];
    PWValueGroup* values;
    [self presetValuesModeForContext:context object:nil options:options values:&values];
    NSArray* valueNames = [self unlocalizedValueNamesForContext:context];
    __block NSUInteger index = 0;
    __block NSString* result;
    [values deepEnumerateValuesWithCategories:PWValueCategoryMaskAll
                                   usingBlock:^(id iValue, PWValueCategory iCategory, BOOL *stop)
     {
         if([iValue isEqual:value])
         {
             result = valueNames[index];
             *stop = YES;
         }
         index++;
     }];
    return result;
}

- (BOOL)       value:(id*)outValue
  forUnlocalizedName:(NSString*)name
             context:(id <PWValueTypeContext>)context
              object:(id)object
             options:(NSDictionary*)options
{
    NSParameterAssert(outValue);

    PWValueGroup* values;

    PWValueTypePresetValuesMode mode = [self presetValuesModeForContext:context object:object options:options values:&values];
    if((mode & PWValueTypeNilIsPresetValue) > 0)
    {
        if([name isEqualToString:[self unlocalizedNilValueNameForContext:context]])
        {
            *outValue = nil;
            return YES;
        }
    }

    __block BOOL result = NO;
    __block NSUInteger index = 0;
    NSArray* valueNames = [self unlocalizedValueNamesForContext:context];
    [values deepEnumerateValuesWithCategories:PWValueCategoryMaskAll
                                   usingBlock:^(id iValue, PWValueCategory iCategory, BOOL *stop)
     {
         NSString* iValueName = valueNames[index];
         if([iValueName isEqualToString:name])
         {
             *outValue = iValue;
             result = YES;
             *stop = YES;
         }
         index++;
     }];
    return result;
}

- (NSString*)unlocalizedNameForValue:(id)value
{
    return [self unlocalizedNameForValue:value context:nil object:nil options:nil];
}

- (BOOL)value:(id*)outValue forUnlocalizedName:(NSString*)name
{
    return [self value:outValue forUnlocalizedName:name context:nil object:nil options:nil];
}
@end

#pragma mark -

@implementation PWArrayValueType

- (instancetype)initWithItemClass:(Class)itemClass
{
    if(self = [super initWithFallbackKeyPath:nil presetValuesBlock:nil])
    {
        _itemClass = itemClass;
    }
    return self;
}

- (Class)valueClass
{
    return NSArray.class;
}

@end

#pragma mark -

@implementation PWDictionaryValueType

- (Class)valueClass
{
    return NSDictionary.class;
}

@end

#pragma mark -

@implementation PWWeekDayValueType

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
    if(outValues)
    {
        PWValueGroup* values = [[PWValueGroup alloc] init];
        for(PWWeekDay day=PWSunday; day<=PWSaturday; day++)
            [values addValue:@(day)];
        [values makeImmutable];
        *outValues = values;
    }
    return PWValueTypeForcesPresetValues;
}

- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context
{
    return @[@"sunday", @"monday", @"tuesday", @"wednesday", @"thursday", @"friday", @"saturday"];
}

+ (PWWeekDay)weekDayFromNSWeekDay:(NSInteger)weekDay
{
    return (weekDay + 6) % 7;
}

+ (PWWeekDay)weekDayForDate:(NSDate*)date calendar:(NSCalendar*)calendar
{
    NSParameterAssert(date);
    NSParameterAssert(calendar);

    NSDateComponents* dateComponents = [calendar components:NSCalendarUnitWeekday
                                                   fromDate:date];
    return [self weekDayFromNSWeekDay:dateComponents.weekday];
}

- (NSString*)localizationKeyPrefixForContext:(id<PWValueTypeContext>)context
{
    return @"valueType.weekDay.";
}

- (id<NSCopying>)formatterCacheKeyForContext:(id<PWValueTypeContext>)context
                                     options:(NSDictionary*)options
                                      object:(id)object
                                     keyPath:(NSString*)keyPath
{
    return @[self.class,
             options ? [options copy] : NSNull.null];
}

@end

#pragma mark -

@implementation PWWeekDaysValueType

// Returns formatter which accepts and creates a comma-separated (for import/export space-separated) list of week day names
- (NSFormatter*)directFormatterForContext:(id<PWValueTypeContext>)context
                                  options:(NSDictionary *)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    NSString* language = context.locality.language;

    NSArray* unlocalizedNames = @[@"sunday", @"monday", @"tuesday", @"wednesday", @"thursday", @"friday", @"saturday"];
    BOOL forExport = [options[PWValueTypeFormatterForImportExportKey] boolValue] ;
    NSArray* names;
    if(forExport || [language isEqualToString:PWLanguageNonLocalized])
       names = unlocalizedNames;
    else
    {
        NSBundle* bundle = [NSBundle bundleForClass:PWWeekDaysValueType.class];
        PWLocalizer* localizer = [bundle localizerForLanguage:language];
        NSString* prefix = [self localizationKeyPrefixForContext:context];
        names = [unlocalizedNames map:^id(NSString* unlocalizedName) {
            return [localizer localizedStringForKey:[prefix stringByAppendingString:unlocalizedName]
                                              value:unlocalizedName];
        }];
    }
    
    PWBlockFormatter* formatter = [[PWBlockFormatter alloc] init];
    formatter.toStringBlock = ^(PWBlockFormatter* blockFormatter, id obj) {
        PWWeekDayMask mask = [obj intValue];
        NSMutableString* string = [NSMutableString string];
        NSString* separator = forExport ? @" " : @", ";
        for(PWWeekDay iDay=PWSunday; iDay<=PWSaturday; iDay++)
        {
            if((mask & (1<<iDay))>0)
            {
                if(string.length > 0)
                    [string appendString:separator];
                [string appendString:names[iDay]];
            }
        }
        return string;
    };

    formatter.toObjectValueBlock = ^BOOL(PWBlockFormatter* blockFormatter, id* outValue, NSString* string, NSString** outErrorString) {
        NSString* separator = forExport ? @" " : @",";
        NSArray* inNames = [string componentsSeparatedByString:separator];
        inNames = [inNames map:^id(id obj) {
            return [[obj lowercaseString] stringByTrimmingSpaces];
        }];

        PWWeekDayMask mask = 0;
        for(PWWeekDay iDay=PWSunday; iDay<=PWSaturday; iDay++)
            if([inNames containsObject:[names[iDay] lowercaseString]])
                mask |= (1<<iDay);
        *outValue = @(mask);
        return YES;
    };
    return formatter;

}

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
    PWValueTypePresetValuesMode mode = [super presetValuesModeForContext:context object:object options:options values:outValues];
    mode |= PWValueTypePresetValuesArePartOfCollection;
    return mode;
}

- (NSString*)localizationKeyPrefixForContext:(id<PWValueTypeContext>)context
{
    return @"valueType.weekDay.";
}
@end

#pragma mark -

@implementation PWLocaleValueType

- (Class)valueClass
{
    return NSLocale.class;
}

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id<PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                   values:(PWValueGroup**)outValues
{
    if(outValues)
    {
        // Create a list of available locales
        NSArray* locales = [[NSLocale availableLocaleIdentifiers] map:^(NSString* localeIdentifier) {
            return [[NSLocale alloc] initWithLocaleIdentifier:localeIdentifier];
        }];
        
        // Sort the list of the locales by its name in the locality of the context
        NSLocale* baseLocale = [[NSLocale alloc] initWithLocaleIdentifier:context.locality.language];
        NSArray* valuesArray = [locales sortedArrayUsingComparator:^(NSLocale* locale1, NSLocale* locale2) {
            NSString* locale1Name = [baseLocale displayNameForKey:NSLocaleIdentifier value:locale1.localeIdentifier];
            NSString* locale2Name = [baseLocale displayNameForKey:NSLocaleIdentifier value:locale2.localeIdentifier];
            return [locale1Name caseInsensitiveCompare:locale2Name];
        }];
        *outValues = [PWValueGroup groupWithValues:valuesArray];
    }
    return PWValueTypeForcesPresetValues;
}

- (NSFormatter*)directFormatterForContext:(id<PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    PWBlockFormatter* formatter = [[PWBlockFormatter alloc] init];
    
    if([options[PWValueTypeFormatterForImportExportKey] boolValue])
    {
        formatter.toStringBlock = ^(PWBlockFormatter* blockFormatter, NSLocale* locale) {
            return locale.localeIdentifier;
        };
        formatter.toObjectValueBlock = ^(PWBlockFormatter* blockFormatter, id* objectValue, NSString* string, NSString** errorDesc) {
            *objectValue = [[NSLocale alloc] initWithLocaleIdentifier:string];
            return YES;
        };
    }
    else
    {
        NSLocale* baseLocale = [[NSLocale alloc] initWithLocaleIdentifier:context.locality.language];
        formatter.toStringBlock = ^(PWBlockFormatter* blockFormatter, NSLocale* locale) {
            return [baseLocale displayNameForKey:NSLocaleIdentifier value:locale.localeIdentifier];
        };
        formatter.toObjectValueBlock = ^(PWBlockFormatter* blockFormatter, id* objectValue, NSString* string, NSString** errorDesc) {
            NSAssert(NO, nil);
            return NO;
        };
    }
    return formatter;
}

@end

#pragma mark -

@implementation PWTimeZoneValueType

- (Class)valueClass
{
    return NSTimeZone.class;
}

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id<PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                   values:(PWValueGroup**)outValues
{
    if(outValues)
        *outValues = [PWValueGroup groupWithValues:[NSTimeZone.knownTimeZoneNames map:^(NSString* timeZoneName) {
            return [NSTimeZone timeZoneWithName:timeZoneName];
        }]];
    return PWValueTypeForcesPresetValues;
}

- (NSFormatter*)directFormatterForContext:(id<PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    PWBlockFormatter* formatter = [[PWBlockFormatter alloc] init];
    
    formatter.toStringBlock = ^(PWBlockFormatter* blockFormatter, NSTimeZone* timeZone) {
        return timeZone.name;
    };
    formatter.toObjectValueBlock = ^(PWBlockFormatter* blockFormatter, id* objectValue, NSString* string, NSString** errorDesc) {
        *objectValue = [[NSTimeZone alloc] initWithName:string];
        return YES;
    };
    
    return formatter;
}

@end

#pragma mark -

@implementation PWLanguageValueType

- (Class)valueClass
{
    return NSString.class;
}

+ (NSArray*) localizations
{
    return NSBundle.mainBundle.localizations;
}

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id<PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                   values:(PWValueGroup**)outValues
{
    // Note: we return only localizations that are present in the main bundle.
    if(outValues)
        *outValues = [PWValueGroup groupWithValues:self.class.localizations];
    return PWValueTypeForcesPresetValues;
}

- (NSFormatter*)directFormatterForContext:(id<PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    PWBlockFormatter* formatter = [[PWBlockFormatter alloc] init];
    if([options[PWValueTypeFormatterForImportExportKey] boolValue])
    {
        formatter.toStringBlock = ^(PWBlockFormatter* blockFormatter, NSString* languageIdentifier) {
            return languageIdentifier;
        };
        formatter.toObjectValueBlock = ^(PWBlockFormatter* blockFormatter, id* objectValue, NSString* string, NSString** errorDesc) {
            *objectValue = string;
            return YES;
        };
    }
    else
    {
        NSLocale* locale;
        if(context)
            locale = context.locality.locale;
        else
        {
            // Note: We can not directly use NSLocale.currentLocale because then language display names would always be translated into the
            //       first language of the languages list. For example: If languages contains "es, de, en", the app language would be "de (assumed we provide no spanish translations).
            //       NSLocale.currentLocale.localeIdentifier would return "de_DE" but [displayNameForKey:NSLocaleLanguageCode value:@"de"]
            //       would return the spanish translation for "de" instead of the german translation.
            //       In order to fix this we create a new locale by using the application language.

            NSString* appLanguageIdentifier = [NSBundle preferredLocalizationsFromArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"AppleLanguages"]].firstObject;
            locale = [[NSLocale alloc] initWithLocaleIdentifier:appLanguageIdentifier];
        }

        formatter.toStringBlock = ^(PWBlockFormatter* blockFormatter, NSString* languageIdentifier) {
            return [locale displayNameForKey:NSLocaleLanguageCode value:languageIdentifier];
        };
        formatter.toObjectValueBlock = ^(PWBlockFormatter* blockFormatter, id* objectValue, NSString* string, NSString** errorDesc) {
            NSString* languageIdentifier = [self.class.localizations match:^BOOL(NSString* identifier) {
                return [[locale displayNameForKey:NSLocaleLanguageCode value:identifier] isEqualToString:string];
            }];
            if(languageIdentifier)
            {
                *objectValue = languageIdentifier;
                return YES;
            }
            NSAssert(NO, nil);
            return NO;
        };
    }
    return formatter;
}

@end

#pragma mark -

@implementation PWByteCountValueType

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    if([options[PWValueTypeFormatterForImportExportKey] boolValue])
        return [super directFormatterForContext:context options:options object:object keyPath:keyPath];
    
    // TODO: I could not find a way to set the locale/language of a NSByteCountFormatter, so we can currently only deal with
    // default system language.
    return [[NSByteCountFormatter alloc] init];
}
@end
