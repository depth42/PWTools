//
//  PWLocality.h
//  PWFoundation
//
//  Created by Frank Illenberger on 10.02.10.
//
//

#import <PWFoundation/PWValueTypes.h>

typedef NS_ENUM (int, PWUnitPosition)
{
    PWUnitBeforeAmount       = 1<<0,
    PWUnitSeparatedWithSpace = 1<<1,
    
    PWUnitAfterAmountWithoutSpace  = 0,
    PWUnitBeforeAmountWithoutSpace = PWUnitBeforeAmount,
    PWUnitAfterAmountWithSpace     = PWUnitSeparatedWithSpace,
    PWUnitBeforeAmountWithSpace    = PWUnitBeforeAmount | PWUnitSeparatedWithSpace,
};

typedef NS_ENUM (int, PWDateFormatLeadingZeroIndex)
{
    PWDateFormatLeadingZeroNone = -1,

    PWDateFormatLeadingZeroMonthIndex = 0,
    PWDateFormatLeadingZeroDayIndex,
    PWDateFormatLeadingZeroHourIndex,
    PWDateFormatLeadingZeroMinuteIndex,
    PWDateFormatLeadingZeroSecondIndex,

    PWDateFormatLeadingZeroCount
};

// Information about the use of leading zeros in different parts of date and time formats is collected in this
// structure, see +[PWLocality determineLeadingZerosFromLocale].
// PWBoolUndefined means that none of the four standard date and time formats contained the unit.
// PWBoolMixed means that the four standard date and time formats are non-unique for this unit.
typedef struct PWDateFormatLeadingZeros {
    PWExtendedBool leadingZeros_[PWDateFormatLeadingZeroCount];
} PWDateFormatLeadingZeros;


@interface PWLocality : NSObject <PWValueTypeContext, NSCopying>

@property (nonatomic, readonly, strong) NSLocale*        locale;
@property (nonatomic, readonly, copy)   NSString*        language;
@property (nonatomic, readonly, copy)   NSString*        currencySymbol;
@property (nonatomic, readonly)         PWUnitPosition   currencySymbolPosition;
@property (nonatomic, readonly, strong) NSCalendar*      calendar;

// Used to decide whether the now date needs to be converted to the GMT time zone.
@property (nonatomic, readonly)         BOOL             ignoresTimeZone;

// Designated initializer
- (instancetype)  initWithLocale:(NSLocale*)locale
              language:(NSString*)language
        currencySymbol:(NSString*)symbol
currencySymbolPosition:(PWUnitPosition)currencySymbolPosition
              calendar:(NSCalendar*)calendar
       ignoresTimeZone:(BOOL)ignoresTimeZone;

- (instancetype)  initWithLocale:(NSLocale*)locale
              language:(NSString*)language
        currencySymbol:(NSString*)symbol
currencySymbolPosition:(PWUnitPosition)currencySymbolPosition
              calendar:(NSCalendar*)calendar;

- (instancetype) initWithLocale:(NSLocale*)locale
             language:(NSString*)language;

// Convenience initializer, mainly for tests.
- (instancetype) initWithLocaleIdentifier:(NSString*)identifier language:(NSString*)language;

// In our time scales, we want to automatically adjust whether leading zeros are used according
// to the settings in the system locale. We determine this heuristically by unit by checking whether
// the system settings are uniform. This method returns the result of this analysis by unit.
@property (nonatomic, readonly) PWDateFormatLeadingZeros determineLeadingZerosFromLocale;

// Valid format characters are M, d, h, H, k, K, m, s. All other inputs result in PWDateFormatLeadingZeroNone.
+ (PWDateFormatLeadingZeroIndex) leadingZeroIndexForFormatChar:(unichar)formatChar;

+ (PWLocality*)defaultLocalityForBundle:(NSBundle*)bundle;

@end

extern NSString* const PWLanguageNonLocalized;


@interface PWUnitPositionValueType : PWEnumValueType
@end

@interface PWUnitPositionFormatter : NSFormatter
{
    NSString* unit_;
}

@property (nonatomic, copy) NSString* unit;

@end
