//
//  PWValueTypes.h
//  PWFoundation
//
//  Created by Frank Illenberger on 25.11.10.
//
//

#import <PWFoundation/PWValueType.h>

@interface PWEnumValueType : PWValueType
- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context;  
- (NSString*)unlocalizedNilValueNameForContext:(id <PWValueTypeContext>)context;

// Can be overriden by subclasses to provide a prefix that is prepended to the unlocalized value name
// for lookup in localization tables. The prefix is not used for unlocalized case.
// Useful to differentiate ambiguous localization keys.
// Defaults to nil.
- (NSString*)localizationKeyPrefixForContext:(id <PWValueTypeContext>)context;

- (NSString*)unlocalizedNameForValue:(id)value 
                             context:(id <PWValueTypeContext>)context
                              object:(id)object 
                             options:(NSDictionary*)options;

- (BOOL)       value:(id*)outValue
  forUnlocalizedName:(NSString*)name
             context:(id <PWValueTypeContext>)context
              object:(id)object
             options:(NSDictionary*)options;

// convenience versions for context- and optionless cases
- (NSString*)unlocalizedNameForValue:(id)value;
- (BOOL)value:(id*)outValue forUnlocalizedName:(NSString*)name;
@end

@interface PWDoubleValueType : PWValueType

- (instancetype)initWithFallbackKeyPath:(NSString*)fallbackKeyPath 
            presetValuesBlock:(PWPresetValuesBlock)block
                      minimum:(NSNumber*)minimum
                      maximum:(NSNumber*)maximum
                        steps:(NSNumber*)steps;

@property (nonatomic, readonly, copy) NSNumber* minimum;
@property (nonatomic, readonly, copy) NSNumber* maximum;
@property (nonatomic, readonly, copy) NSNumber* steps;

@end

extern NSString* const PWNumberOfDecimalsFormatKey;
extern NSString* const PWTrailingZerosFormatKey;
extern NSString* const PWTrailingZerosShow;
extern NSString* const PWTrailingZerosHide;

extern NSString* const PWZerosFormatKey;
extern NSString* const PWZerosHide;

@interface PWNumberOfDecimalsValueType : PWEnumValueType       // value type for PWNumberOfDecimalsFormatKey
@end

@interface PWTrailingZerosValueType : PWEnumValueType          // value type for PWTrailingZerosFormatKey
@end

@interface PWZerosValueType : PWEnumValueType                  // value type for PWZerosFormatKey
@end


@interface PWIntegerValueType                   : PWDoubleValueType
@end

extern NSString* const PWBoolFormatterShowsYesNo;

@interface PWBoolValueType                      : PWDoubleValueType
@end

@interface PWMixedBoolValueType                 : PWBoolValueType
@end

@interface PWPercentValueType                   : PWDoubleValueType
@end

@interface PWCurrencyValueType                  : PWDoubleValueType
@end

@interface PWDateTimeValueType                  : PWValueType

// Overwritten in subclasses. Default returns nil.
- (NSString*)localizedFixingStringForContext:(id<PWValueTypeContext>)context;

// Overwritten in subclasses. Default returns nil.
- (NSString*)localizedGeneralFixingStringForContext:(id<PWValueTypeContext>)context;

@end

extern NSString* const PWDateFormatKey;            // A nil value under this key creates the same formatter as the medium setting, but hints that the format might be adjusted by a controller to fit a certain UI constraint like a column width
extern NSString* const PWDateFormatShort;
extern NSString* const PWDateFormatMedium;
extern NSString* const PWDateFormatLong;
extern NSString* const PWDateFormatNone;

extern NSString* const PWTimeFormatKey;            // A nil value under this key creates the same formatter as the withTime setting, but hints that the format might be adjusted by a controller to fit a certain UI constraint like a column width
extern NSString* const PWTimeFormatWithoutTime;
extern NSString* const PWTimeFormatWithTime;

@interface PWDateFormatValueType : PWEnumValueType          // value type for PWDateFormatKey
@end

@interface PWTimeFormatValueType : PWEnumValueType          // value type for PWTimeFormatKey
@end

@interface PWDateValueType                      : PWDateTimeValueType
@end

@interface PWTimeValueType                      : PWValueType
@end

@interface PWDurationUnitValueType              : PWEnumValueType

- (instancetype)initWithUsesPluralForm:(BOOL)usesPluralForm
              includesNoUnit:(BOOL)includesNoUnit;

@property (nonatomic, readonly) BOOL usesPluralForm;    // Defaults to NO
@property (nonatomic, readonly) BOOL includesNoUnit;    // Defaults to NO
@end

@interface PWStringValueType                    : PWValueType
@end

@interface PWStringEncodingValueType            : PWEnumValueType
@end

@interface PWURLStringValueType                 : PWStringValueType
@end

@interface PWURLValueType                       : PWValueType
@end

@interface PWAttributedStringValueType          : PWValueType
@end

@interface PWFullAttributedStringValueType      : PWAttributedStringValueType
@end

@interface PWLongFullAttributedStringValueType  : PWFullAttributedStringValueType
@end

@interface PWDataValueType              : PWValueType
@end

@interface PWArrayValueType             : PWValueType
- (instancetype)initWithItemClass:(Class)itemClass;
@property (nonatomic, readonly, strong) Class itemClass;
@end

@interface PWDictionaryValueType        : PWValueType
@end

typedef NS_ENUM (PWInteger, PWWeekDay)
{
    PWSunday = 0,
    PWMonday,
    PWTuesday,
    PWWednesday,
    PWThursday,
    PWFriday,
    PWSaturday,
};

typedef NS_ENUM (PWInteger, PWWeekDayMask)
{
    PWSundayMask    = 1<<PWSunday,
    PWMondayMask    = 1<<PWMonday,
    PWTuesdayMask   = 1<<PWTuesday,
    PWWednesdayMask = 1<<PWWednesday,
    PWThursdayMask  = 1<<PWThursday,
    PWFridayMask    = 1<<PWFriday,
    PWSaturdayMask  = 1<<PWSaturday
};


@interface PWWeekDayValueType : PWEnumValueType

+ (PWWeekDay)weekDayFromNSWeekDay:(NSInteger)weekDay;
+ (PWWeekDay)weekDayForDate:(NSDate*)date calendar:(NSCalendar*)calendar;
@end

@interface PWWeekDaysValueType : PWEnumValueType
@end

@interface PWLocaleValueType : PWValueType
@end

@interface PWTimeZoneValueType : PWValueType
@end

@interface PWLanguageValueType : PWValueType

// Returns the localizations found in the main bundle
+ (NSArray*) localizations;

@end

@interface PWByteCountValueType : PWIntegerValueType
@end
