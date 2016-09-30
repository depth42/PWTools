//
//  PWCurrencyFormatter.m
//  PWFoundation
//
//  Created by Frank Illenberger on 04.03.10.
//
//

#import "PWCurrencyFormatter.h"
#import "PWLocality.h"
#import "PWDispatch.h"
#import "NSFormatter-PWExtensions.h"
#import "NSString-PWExtensions.h"

@implementation PWCurrencyFormatter
{
    NSString* _originalNegativeFormat;
}


- (instancetype)initWithLocality:(PWLocality*)locality
            hideZeroes:(BOOL)hideZeroes
{
    NSParameterAssert(locality);
    
    if(self = [super init])
    {
        _locality   = locality;
        _hideZeroes = hideZeroes;

        self.locale = locality.locale;
        self.lenient = YES;
        NSString* symbol = locality.currencySymbol;
        
        if([symbol isEqualToString:@""])
            self.numberStyle = NSNumberFormatterDecimalStyle;
        else
        {
            // If no symbol (nil) is specified, the symbol and position are configured from the NSLocale
            self.numberStyle = NSNumberFormatterCurrencyStyle;
            if(symbol)
            {
                PWUnitPosition position = locality.currencySymbolPosition;
                self.positiveFormat = [self.class formatByAdjustingFormat:self.positiveFormat
                                                         toSymbolPosition:position];

                _originalNegativeFormat = [self.class formatByAdjustingFormat:self.negativeFormat
                                                         toSymbolPosition:position];

                self.negativeFormat = [self.class formatByAdjustingFormat:self.localeAdjustedNegativeFormat
                                                         toSymbolPosition:position];

                self.zeroSymbol = hideZeroes ? @"" : nil;
                self.currencySymbol = locality.currencySymbol;
            }
            else
                self.negativeFormat = self.localeAdjustedNegativeFormat;
        }
    }
    return self;
}

- (BOOL)getObjectValue:(__autoreleasing id *)anObject forString:(NSString *)string error:(NSError *__autoreleasing *)outError
{
    // Fix for MDEV-3861: When the zeroSymbol is an empty string or string only containing spaces, we need to strip it
    // first, because otherwise it crashes due to a bug in NSNumberFormatter.
    if(_hideZeroes)
        string = string.stringByTrimmingSpaces;
    
    BOOL success = [super getObjectValue:anObject forString:string error:outError];

    // If the currency symbol matches the currency symbol of the locale everything works as expected.
    // Negative values like -$66 are formatted without an error -> ($66.00).
    // If the currency symbol is different like -kr66 formatting does not succeed - expected: (kr66.00).
    // But if we do not apply our adjustment in localeAdjustedNegativeFormat it works.
    // So we try it again with the none adjusted format:
    if(!success)
    {
        NSString* format = self.negativeFormat;
        self.negativeFormat = _originalNegativeFormat;
        success = [super getObjectValue:anObject forString:string error:outError];
        self.negativeFormat = format;
    }

    // Fix for MDEV-2820: With norwegian language and English locale, NSNumberFormatter
    // uses a special minus character (U+2212) for negative values. Sadly, the formatter
    // this is unable to leniently accept entered regular - signs. We work around this
    // by replacing trying to replace regular minus character with the special ones.
    if(!success && [string rangeOfString:@"-"].location != NSNotFound)
    {
        string = [string stringByReplacingOccurrencesOfString:@"-" /* regular minus */
                                                   withString:@"−" /* special minus (U+2212) */];
        success = [super getObjectValue:anObject forString:string error:outError];
    }

    return success;
}


+ (NSRegularExpression*)numberFormatRegEx
{
    static NSRegularExpression* regex;
    PWDispatchOnce(^{
        regex = [[NSRegularExpression alloc] initWithPattern:@"#[#,#0.]*0" options:0 error:NULL];
    });
    return regex;
}

// Starting with iOS 8 and OS X 10.10, the default number format for negative currency values in the en_US locale seems to have changed from ($42.42) to -$42.42.
// We regard this as a bug and reported it in rdar://18718954
// This method works around this by manually adjusting the negativeFormat for certain locales.
- (NSString*)localeAdjustedNegativeFormat
{
    // make sure the locale identifier is canonical
    NSString* localeIdentifier = [_locality.locale.localeIdentifier stringByReplacingOccurrencesOfString:@"-" withString:@"_"];
    if ([localeIdentifier isEqualToString:@"en_US"] || [localeIdentifier isEqualToString:@"fr_NE"])
        return [NSString stringWithFormat:@"(%@)", self.positiveFormat];
    else
        return self.negativeFormat;
}

+ (NSString*)formatByAdjustingFormat:(NSString*)format
                    toSymbolPosition:(PWUnitPosition)position
{
    NSParameterAssert(format);

    NSTextCheckingResult* match = [self.numberFormatRegEx firstMatchInString:format
                                                                     options:0
                                                                       range:NSMakeRange(0, format.length)];
    NSString* numberFormat = [format substringWithMatch:match rangeIndex:0];
    NSAssert(numberFormat.length > 0, nil);

    NSString* unitFormat;
    switch(position)
    {
        case PWUnitAfterAmountWithoutSpace:
            unitFormat = @"%@¤";
            break;
        case PWUnitBeforeAmountWithoutSpace:
            unitFormat = @"¤%@";
            break;
        case PWUnitAfterAmountWithSpace:
            unitFormat = @"%@ ¤";
            break;
        case PWUnitBeforeAmountWithSpace:
            unitFormat = @"¤ %@";
            break;
    }

    NSString* result = [NSString stringWithFormat:unitFormat, numberFormat];
    NSUInteger parenthesesLocation = [format rangeOfString:@"("].location;
    if(parenthesesLocation != NSNotFound)
    {
        // Note: Some locales like the persian fa_AF have a prefix character before the parentheses.
        NSString* prefix = [format substringToIndex:parenthesesLocation];
        result = [NSString stringWithFormat:@"%@(%@)", prefix, result];
    }
    return result;
}
@end
