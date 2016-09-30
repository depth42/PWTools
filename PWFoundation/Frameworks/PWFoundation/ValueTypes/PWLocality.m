//
//  PWLocality.m
//  PWFoundation
//
//  Created by Frank Illenberger on 10.02.10.
//
//

#import "PWLocality.h"
#import "PWValueGroup.h"
#import "NSCalendar-PWExtensions.h"
#import "NSObject-PWExtensions.h"
#import "NSString-PWExtensions.h"
#import "NSArray-PWExtensions.h"
#import "NSDateFormatter-PWExtensions.h"

@implementation PWLocality

@synthesize locale                 = locale_;
@synthesize language               = language_;
@synthesize currencySymbol         = currencySymbol_;
@synthesize currencySymbolPosition = currencySymbolPosition_;
@synthesize calendar               = calendar_;
@synthesize ignoresTimeZone        = ignoresTimeZone_;

// Designated initializer
- (instancetype)  initWithLocale:(NSLocale*)locale
              language:(NSString*)language
        currencySymbol:(NSString*)symbol
currencySymbolPosition:(PWUnitPosition)currencySymbolPosition
              calendar:(NSCalendar*)calendar
       ignoresTimeZone:(BOOL)ignoresTimeZone
{
    if ((self = [super init]) != nil) {
        // Make sure locale, language and calendar are always valid (kb, 21.5.10).
        locale_                 = locale ? locale : [NSLocale currentLocale];
        language_               = (language.length > 0) ? [language copy] : @"English";
        currencySymbol_         = symbol.stringByTrimmingSpaces;
        currencySymbolPosition_ = currencySymbolPosition;
        calendar_               = calendar ? calendar : [locale_ objectForKey:NSLocaleCalendar];
        ignoresTimeZone_        = ignoresTimeZone;
    }
    return self;
}

- (instancetype)  initWithLocale:(NSLocale*)locale
              language:(NSString*)language
        currencySymbol:(NSString*)symbol
currencySymbolPosition:(PWUnitPosition)currencySymbolPosition
              calendar:(NSCalendar*)calendar
{
    return [self initWithLocale:locale
                       language:language
                 currencySymbol:symbol
         currencySymbolPosition:currencySymbolPosition
                       calendar:calendar
                ignoresTimeZone:NO];
}

- (instancetype) initWithLocale:(NSLocale*)locale
             language:(NSString*)language
{
    return [self initWithLocale:locale
                       language:language
                 currencySymbol:nil
         currencySymbolPosition:PWUnitAfterAmountWithoutSpace
                       calendar:nil];
}

- (instancetype) initWithLocaleIdentifier:(NSString*)identifier language:(NSString*)language
{
    return [self initWithLocale:[[NSLocale alloc] initWithLocaleIdentifier:identifier]
                       language:language
                 currencySymbol:nil
         currencySymbolPosition:PWUnitAfterAmountWithoutSpace
                       calendar:nil];
}

- (instancetype) init
{
    return [self initWithLocale:nil 
                       language:nil
                 currencySymbol:nil
         currencySymbolPosition:PWUnitAfterAmountWithoutSpace
                       calendar:nil];
}

- (PWDateFormatLeadingZeros) determineLeadingZerosFromLocale
{
    PWDateFormatLeadingZeros leadingZeros;
    for (int i = 0; i < PWDateFormatLeadingZeroCount; ++i)
        leadingZeros.leadingZeros_[i] = PWBoolUndefined;
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setLocality:self];
    
    // Iterate through the four standard date/time styles.
    formatter.dateStyle = NSDateFormatterShortStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    [PWLocality applyFormatString:formatter.dateFormat toLeadingZeros:&leadingZeros];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterMediumStyle;
    [PWLocality applyFormatString:formatter.dateFormat toLeadingZeros:&leadingZeros];
    formatter.dateStyle = NSDateFormatterLongStyle;
    formatter.timeStyle = NSDateFormatterLongStyle;
    [PWLocality applyFormatString:formatter.dateFormat toLeadingZeros:&leadingZeros];
    formatter.dateStyle = NSDateFormatterFullStyle;
    formatter.timeStyle = NSDateFormatterFullStyle;
    [PWLocality applyFormatString:formatter.dateFormat toLeadingZeros:&leadingZeros];

    return leadingZeros;
}

+ (void) applyFormatString:(NSString*)formatString toLeadingZeros:(PWDateFormatLeadingZeros*)pLeadingZeros
{
    NSParameterAssert (formatString);
    NSParameterAssert (pLeadingZeros);

    // Look for sequences of 1 or 2 of the format characters recognized by -leadingZeroIndexForFormatChar:
    NSUInteger length = formatString.length;
    unichar currentSequenceCh = 0;
    unichar currentSequenceLength = 0;
    BOOL insideQuotes = NO;
    for (NSUInteger i = 0; i <= length; ++i) {
        // A last pass with ch == 0 conveniently closes the last sequence without special handling.
        unichar ch = (i < length) ? [formatString characterAtIndex:i] : 0;

        // Must ignore any quoted characters.
        // Note: for this purpose two quotes (which maps to a single quote in output) needs no special handling.
        if (insideQuotes) {
            if (ch == '\'')
                insideQuotes = NO;
        }
        else if (ch == '\'') {
            insideQuotes = YES;
            currentSequenceCh = 0;
        }
        else {
            if (ch == currentSequenceCh)
                ++currentSequenceLength;
            else {
                // Handle current sequence
                if (currentSequenceLength <= 2) {
                    PWDateFormatLeadingZeroIndex leadingZeroIndex = [self leadingZeroIndexForFormatChar:currentSequenceCh];
                    if (leadingZeroIndex != PWDateFormatLeadingZeroNone) {
                        PWExtendedBool* target = &pLeadingZeros->leadingZeros_[leadingZeroIndex];
                        PWExtendedBool hasLeadingZero = currentSequenceLength == 2;
                        if (*target == PWBoolUndefined)
                            *target = hasLeadingZero;
                        else if (*target != hasLeadingZero)
                            *target = PWBoolMixed;
                    }
                }
                
                // Restart sequence collection.
                currentSequenceLength = 1;
                currentSequenceCh = ch;
            }
        }
    }
}

+ (PWDateFormatLeadingZeroIndex) leadingZeroIndexForFormatChar:(unichar)formatChar
{
    PWDateFormatLeadingZeroIndex leadingZeroIndex;
    switch (formatChar) {
        case 'M': leadingZeroIndex = PWDateFormatLeadingZeroMonthIndex; break;
        case 'd': leadingZeroIndex = PWDateFormatLeadingZeroDayIndex; break;
        case 'h':
        case 'H':
        case 'k':
        case 'K': leadingZeroIndex = PWDateFormatLeadingZeroHourIndex; break;
        case 'm': leadingZeroIndex = PWDateFormatLeadingZeroMinuteIndex; break;
        case 's': leadingZeroIndex = PWDateFormatLeadingZeroSecondIndex; break;
        default:  leadingZeroIndex = PWDateFormatLeadingZeroNone; break;
    }
    return leadingZeroIndex;
}

+ (PWLocality*)defaultLocalityForBundle:(NSBundle*)bundle
{
    NSParameterAssert(bundle);

    NSString* language = [NSBundle preferredLocalizationsFromArray:bundle.localizations
                                                    forPreferences:nil].firstObject;
    return [[PWLocality alloc] initWithLocale:[NSLocale currentLocale] language:language];
}

- (id)copyWithZone:(NSZone*)zone
{
    return self;
}

- (NSUInteger)hash
{
    // Taken from "The Ruby Programming Language", page 224.
    NSUInteger hash = 17;
    hash = 37 * hash + locale_.localeIdentifier.hash;
    hash = 37 * hash + calendar_.calendarIdentifier.hash;
    hash = 37 * hash + calendar_.locale.hash;
    hash = 37 * hash + calendar_.timeZone.hash;
    hash = 37 * hash + calendar_.firstWeekday;
    hash = 37 * hash + language_.hash;
    hash = 37 * hash + currencySymbol_.hash;
    hash = 37 * hash + currencySymbolPosition_;
    return hash;
}

- (BOOL)isEqual:(id)object
{
    if(![object isKindOfClass:[PWLocality class]])
        return NO;
    PWLocality* locality = object;
    
    return PWEqualObjects(locality.locale.localeIdentifier, locale_.localeIdentifier)
        && [locality.calendar isEqualToCalendar:calendar_]
        && PWEqualObjects(locality.language, language_)
        && PWEqualObjects(locality.currencySymbol, currencySymbol_)
        && (locality.currencySymbolPosition == currencySymbolPosition_);
}

// PWValueTypeContext protocol
- (PWLocality*)locality
{
    return self;
}

- (PWValueType*)valueTypeForKey:(NSString*)key ofClass:(Class)aClass
{
    return [aClass valueTypeForKey:key];
}
@end

#pragma mark

NSString* const PWLanguageNonLocalized = @"NonLocalized";

@implementation PWUnitPositionFormatter

@synthesize unit = unit_;

- (NSString*)stringForObjectValue:(id)anObject
{
    NSParameterAssert(!anObject || [anObject isKindOfClass:NSNumber.class]);
    NSString* unit = unit_ ? unit_ : @"";
    switch([anObject intValue])
    {
        case PWUnitAfterAmountWithoutSpace:
            return [NSString stringWithFormat:@"1%@",  unit];
        case PWUnitBeforeAmountWithoutSpace:
            return [NSString stringWithFormat:@"%@1",  unit];
        case PWUnitAfterAmountWithSpace:
            return [NSString stringWithFormat:@"1 %@", unit];
        case PWUnitBeforeAmountWithSpace:
            return [NSString stringWithFormat:@"%@ 1", unit];
        default:
            NSAssert(NO, nil);
            return nil;
    }
}

- (BOOL)getObjectValue:(id*)anObject 
             forString:(NSString*)string
      errorDescription:(NSString**)error
{
    NSAssert(NO, @"not implemented");
    return NO;
}

@end

#pragma mark

@implementation PWUnitPositionValueType

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                   values:(PWValueGroup**)outValues
{
    if (outValues)
        *outValues = [PWValueGroup groupWithValues:
                      @[@(PWUnitAfterAmountWithoutSpace),
                      @(PWUnitBeforeAmountWithoutSpace),
                      @(PWUnitAfterAmountWithSpace),
                      @(PWUnitBeforeAmountWithSpace)]];
    return PWValueTypeForcesPresetValues;
}

- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context
{
    return @[@"afterAmount", @"beforeAmount", @"afterAmountWithSpace", @"beforeAmountWithSpace"];
}    

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    // For import/export we use direct descriptions of the enum options
    if([options[PWValueTypeFormatterForImportExportKey] boolValue])
        return [super directFormatterForContext:context options:options object:object keyPath:keyPath];
    else
    {
        // For human presentation, we present a formatted example, like "$1" or "1 kg"
        PWUnitPositionFormatter* formatter = [[PWUnitPositionFormatter alloc] init];
        // Sublcasses can override unit of formatter here or in configureFormatter:forObject:keyPath:
        formatter.unit = context.locality.currencySymbol;
        return formatter;
    }
}

- (NSString*)localizationKeyPrefixForContext:(id<PWValueTypeContext>)context
{
    return @"valueType.unitPosition.";
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
