//
//  PWValueTypeTest.m
//  PWFoundation
//
//  Created by Frank Illenberger on 02.03.10.
//
//

#import "PWValueTypeTest.h"
#import "PWValueTypes.h"
#import "PWLocality.h"
#import "PWErrors.h"
#import "PWValueGroup.h"
#import "PWValueTypeTestObject.h"
#import "NSObject-PWExtensions.h"
#import "NSArray-PWExtensions.h"

@interface PWValueTypeTestContext : NSObject <PWValueTypeContext>
@property (nonatomic, readwrite, strong) PWLocality* locality;
@end

@implementation PWValueTypeTestContext

;

- (PWValueType*)valueTypeForKey:(NSString*)key ofClass:(Class)aClass
{
    return [NSObject valueTypeForKey:key];
}

@synthesize locality = locality_;
@end


@interface PWTestEnumType : PWEnumValueType
@end

@implementation PWTestEnumType

;

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
    if(outValues)
        *outValues = [PWValueGroup groupWithValues:@[@1, @2]];
    return PWValueTypeForcesPresetValues;
}

- (NSArray*)unlocalizedValueNamesForContext:(id <PWValueTypeContext>)context
{
    return @[@"valueA", @"valueB"];
}

- (NSString*)unlocalizedNilValueNameForContext:(id <PWValueTypeContext>)context
{
    return @"nada";
}

- (NSString*)localizationKeyPrefixForContext:(id<PWValueTypeContext>)context
{
    if([context.locality.language isEqualToString:@"German"])
        return @"prefix_";
    else
        return nil;
}

@end


@implementation PWValueTypeTest
{
    PWValueTypeTestContext* germanContext_;
    PWValueTypeTestContext* englishContext_;
}

- (void)testSingletons
{
    PWValueType* doubleType  = [PWDoubleValueType valueType];
    XCTAssertTrue([doubleType isKindOfClass:[PWDoubleValueType class]]);
    XCTAssertEqual(doubleType, [PWDoubleValueType valueType]);
 
    PWValueType* integerType  = [PWIntegerValueType valueType];
    XCTAssertTrue([integerType isKindOfClass:[PWIntegerValueType class]]);
    XCTAssertEqual(integerType, [PWIntegerValueType valueType]);
}

- (PWValueTypeTestContext*)germanContext
{
    if(!germanContext_)
    {
        germanContext_ = [[PWValueTypeTestContext alloc] init];

        NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"de-DE"];
        // Setup for time-zone-less operation as we need it in Merlin.
        NSCalendar* calendar = [[locale objectForKey:NSLocaleCalendar] copy];
        calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        
        germanContext_.locality = [[PWLocality alloc] initWithLocale:locale
                                                            language:@"German"
                                                      currencySymbol:nil
                                              currencySymbolPosition:PWUnitAfterAmountWithoutSpace
                                                            calendar:calendar];
    }
    return germanContext_;
}

- (PWValueTypeTestContext*)englishContext
{
    if(!englishContext_)
    {
        englishContext_ = [[PWValueTypeTestContext alloc] init];
        
        NSLocale* locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en-US"];
        
        // Setup for time-zone-less operation as we need it in Merlin.
        NSCalendar* calendar = [[locale objectForKey:NSLocaleCalendar] copy];
        calendar.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
        
        englishContext_.locality = [[PWLocality alloc] initWithLocale:locale
                                                             language:@"English"
                                                       currencySymbol:nil
                                               currencySymbolPosition:PWUnitAfterAmountWithoutSpace
                                                             calendar:calendar];
    }
    return englishContext_;
}

- (void)testDoubleType
{
    __block id <PWValueTypeContext> savedContext = nil;
    __block id savedObject = nil;
    PWValueTypeTestContext* context = [[PWValueTypeTestContext alloc] init];
    PWValueType* type  = [[PWDoubleValueType alloc] initWithFallbackKeyPath:nil
                                                          presetValuesBlock:^PWValueTypePresetValuesMode(id <PWValueTypeContext> ctx, id obj, NSDictionary* options, PWValueGroup** outValues) {
                                                              savedObject = obj;
                                                              savedContext = ctx;
                                                              if(outValues)
                                                                  *outValues = [PWValueGroup groupWithValues:@[@42.0]];
                                                              return PWValueTypeAllowsPresetValues;
                                                          }];
    XCTAssertEqual(type.valueClass, NSNumber.class);
    NSFormatter* germanFormatter = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    
    NSNumber* value = @42.5;
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:value], @"42,5");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:value], @"42.5");
    
    PWValueGroup* values;
    PWValueTypePresetValuesMode mode = [type presetValuesModeForContext:context object:self options:nil values:&values];
    XCTAssertEqualObjects(values.deepValues, @[@42.0]);
    XCTAssertEqual(savedObject, self);
    XCTAssertEqual(savedContext, context);
    XCTAssertEqual(mode, PWValueTypeAllowsPresetValues);
}

- (void)testIntegerType
{
    PWValueType* type  = [PWIntegerValueType valueType];
    XCTAssertEqual(type.valueClass, NSNumber.class);
    NSFormatter* germanFormatter = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    
    NSNumber* value = @42;
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:value], @"42");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:value], @"42");
}

- (void)testPercentType
{
    PWValueType* type  = [[PWPercentValueType alloc] initWithFallbackKeyPath:nil presetValuesBlock:nil];
    XCTAssertEqual(type.valueClass, NSNumber.class);
    NSFormatter* germanFormatter = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    
    NSNumber* value = @0.423561;
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:value], @"42,36 %");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:value], @"42.36%");
}

- (void)testCurrencyType
{
    PWValueType* type  = [PWCurrencyValueType valueType];
    XCTAssertEqual(type.valueClass, NSNumber.class);
    NSFormatter* germanFormatter = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    
    NSNumber* value = @123.25;
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:value], @"123,25 €");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:value], @"$123.25");
}


- (void)testDateType
{
    PWValueType* type  = [PWDateValueType valueType];
    XCTAssertEqual(type.valueClass, NSDate.class);
    
    NSFormatter* germanFormatter  = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    
    NSDate* date = [NSDate dateWithTimeIntervalSinceReferenceDate:31.0*24.0*3600.0];
    
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:date], @"01.02.2001");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:date], @"Feb 1, 2001");
    
    NSDictionary* options = @{PWValueTypeFormatterForImportExportKey: @YES};
    NSFormatter* isoFormatter = [type formatterForContext:self.englishContext options:options object:nil keyPath:nil];
    XCTAssertEqualObjects([isoFormatter stringForObjectValue:date], @"2001-02-01");
}

- (void)testTimeType
{
    PWValueType* type = [PWTimeValueType valueType];
    XCTAssertEqual(type.valueClass, NSNumber.class);

    NSFormatter* germanFormatter  = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    NSFormatter* importFormatter  = [type formatterForContext:self.englishContext
                                                      options:@{PWValueTypeFormatterForImportExportKey: @YES}
                                                       object:nil
                                                      keyPath:nil];

    NSNumber* time = @(13.5*3600.0);

    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:time], @"13:30");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:time], @"1:30 PM");
    XCTAssertEqualObjects([importFormatter stringForObjectValue:time], @"13:30:00");

    XCTAssertTrue([germanFormatter getObjectValue:&time forString:@"13:45" errorDescription:NULL]);
    XCTAssertEqualObjects(time, @(13.75*3600.0));

    XCTAssertTrue([englishFormatter getObjectValue:&time forString:@"1:15 PM" errorDescription:NULL]);
    XCTAssertEqualObjects(time, @(13.25*3600.0));

    XCTAssertTrue([importFormatter getObjectValue:&time forString:@"13:45" errorDescription:NULL]);
    XCTAssertEqualObjects(time, @(13.75*3600.0));
}
     
- (void)testStringType
{
    PWValueType* type  = [PWStringValueType valueType];
    XCTAssertEqual(type.valueClass, NSString.class);

    NSFormatter* germanFormatter  = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    
    NSString* string = @"Dr. Sheldon Cooper";
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:string], string);
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:string], string);
}

- (void)testAttributedStringType
{
    PWValueType* type  = [PWAttributedStringValueType valueType];
    XCTAssertEqual(type.valueClass, NSAttributedString.class);
    
    NSFormatter* germanFormatter  = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    
    NSAttributedString* string = [[NSAttributedString alloc] initWithString:@"Dr. Sheldon Cooper"];
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:string], string.string);
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:string], string.string);
}

- (void)testDataType
{
    PWValueType* type  = [PWDataValueType valueType];
    XCTAssertEqual(type.valueClass, NSData.class);
  
    NSFormatter* germanFormatter  = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    
    NSData* data = [@"test" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:data], nil);
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:data], nil);
}

- (void)testEnumType
{
    PWValueType* type = [PWTestEnumType valueType];
    XCTAssertEqual(type.valueClass, NSNumber.class);
    
    NSFormatter* germanFormatter  = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:@1], @"Wert A");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:@2], @"Value B");
    
    PWValueTypePresetValuesMode mode = [type presetValuesModeForContext:self.germanContext object:nil options:nil values:NULL];
    XCTAssertEqual(mode, PWValueTypeForcesPresetValues);
}

- (void)testValueConversion
{
    PWValueTypeTestContext* context = self.englishContext;
    PWValueType* doubleType     = [PWDoubleValueType valueType];
    PWValueType* intType        = [PWIntegerValueType valueType];
    PWValueType* stringType     = [PWStringValueType valueType];
    PWValueType* boolType       = [PWBoolValueType valueType];
    PWValueType* enumType       = [PWTestEnumType valueType];
    PWValueType* dateType       = [PWDateValueType valueType];
    PWValueType* dateTimeType   = [PWDateTimeValueType valueType];
//    PWValueType* timeType       = [PWTimeValueType valueType];
    
    NSError* error;
    BOOL success;

    NSNumber* doubleValue = @4200.5;
    
    NSNumber* intValue;
    success = [intType value:&intValue context:context object:nil fromValue:doubleValue withType:doubleType context:context object:nil error:&error];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(intValue, @4200);
    
    NSString* stringValue;
    success = [stringType value:&stringValue context:context object:nil fromValue:intValue withType:intType context:context object:nil error:&error];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(stringValue, @"4,200");
    
    success = [doubleType value:&doubleValue context:context object:nil fromValue:stringValue withType:stringType context:context object:nil error:&error];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(doubleValue,@4200.0);
    
    NSNumber* boolValue;
    success = [boolType value:&boolValue context:context object:nil fromValue:doubleValue withType:doubleType context:context object:nil error:&error];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(boolValue,@YES);
    
    success = [stringType value:&stringValue context:context object:nil fromValue:boolValue withType:boolType context:context object:nil error:&error];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(stringValue, @"true");
    
    NSNumber* enumValue = @2;
    success = [stringType value:&stringValue context:context object:nil fromValue:enumValue withType:enumType context:context object:nil error:&error];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(stringValue, @"Value B");
    
    success = [enumType value:&enumValue context:context object:nil fromValue:stringValue withType:stringType context:context object:nil error:&error];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(enumValue, @2);
    
    success = [enumType value:&enumValue context:context object:nil fromValue:@"dumbo" withType:stringType context:context object:nil error:&error];
    XCTAssertFalse(success);
    XCTAssertEqual(error.code, (NSInteger)PWValueTypeConversionError);
    
    NSNumber* otherEnumValue;
    success = [enumType value:&otherEnumValue context:self.germanContext object:nil fromValue:enumValue withType:enumType context:context object:nil error:&error];
    XCTAssertTrue(success);
    XCTAssertEqualObjects(otherEnumValue, enumValue);
    
    NSDateComponents* comps = [[NSDateComponents alloc] init];
    comps.year = 2010;
    comps.month = 2;
    comps.day = 14;
    comps.hour = 12;
    comps.minute = 40;
    NSDate* dateTime = [context.locality.calendar dateFromComponents:comps];
    
    NSDate* date;
    success = [dateType value:&date context:context object:nil fromValue:dateTime withType:dateTimeType context:context object:nil error:&error];
    XCTAssertEqualObjects(date, dateTime);
}

- (void)testFallback
{
    PWValueTypeTestObject* object = [[PWValueTypeTestObject alloc] init];
    object.fallbackValue = @42.0;
    NSNumber* value = @123.25;
   
    PWValueType* type = [object valueTypeForKey:@"value"];
    NSFormatter* formatter = [type formatterForContext:self.englishContext];
    
    // Starting with iOS9/OS X 10.11 SDK, passing nil to stringForObjectValue: creates a compiler warning.
    // We regard this as an error in the SDK and filed a radar on it. In the meantime, we silence the warning.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    XCTAssertEqualObjects([formatter stringForObjectValue:nil], @"");
    formatter = [type formatterForContext:self.englishContext options:nil object:object keyPath:@"value"];

    XCTAssertEqualObjects([formatter stringForObjectValue:value], @"$123.25");
    XCTAssertEqualObjects([formatter stringForObjectValue:nil], @"$42.00");

    // For export
    formatter = [type formatterForContext:self.englishContext
                                  options:@{PWValueTypeFormatterForImportExportKey: @YES}
                                   object:object
                                  keyPath:@"value"];
    XCTAssertEqualObjects([formatter stringForObjectValue:value], @"$123.25");
    XCTAssertEqualObjects([formatter stringForObjectValue:nil], @""); // no fallback for exports
#pragma clang diagnostic pop
}

- (void)testLocaleValueType
{
    PWValueType* type = [PWLocaleValueType valueType];
    
    NSFormatter* germanFormatter = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    NSFormatter* importFormatter = [type formatterForContext:self.englishContext options:@{PWValueTypeFormatterForImportExportKey: @YES}  object:nil keyPath:nil];
    
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]], @"Deutsch (Deutschland)");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]], @"German (Germany)");
    XCTAssertEqualObjects([importFormatter  stringForObjectValue:[[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]], @"de_DE");
    
    NSLocale* value;
    XCTAssertTrue([importFormatter getObjectValue:&value forString:@"de_DE" errorDescription:NULL]);
    XCTAssertEqualObjects(value, [[NSLocale alloc] initWithLocaleIdentifier:@"de_DE"]);
}

- (void)testTimeZoneValueType
{
    PWValueType* type = [PWTimeZoneValueType valueType];
    
    NSFormatter* germanFormatter = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    NSFormatter* importFormatter = [type formatterForContext:self.englishContext options:@{PWValueTypeFormatterForImportExportKey: @YES}  object:nil keyPath:nil];
    
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:[NSTimeZone timeZoneWithName:@"Europe/Berlin"]], @"Europe/Berlin");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:[NSTimeZone timeZoneWithName:@"America/New_York"]], @"America/New_York");
    XCTAssertEqualObjects([importFormatter  stringForObjectValue:[NSTimeZone timeZoneWithName:@"Pacific/Honolulu"]], @"Pacific/Honolulu");
    
    NSLocale* value;
    XCTAssertTrue([importFormatter getObjectValue:&value forString:@"America/New_York" errorDescription:NULL]);
    XCTAssertEqualObjects(value, [NSTimeZone timeZoneWithName:@"America/New_York"]);
}

- (void)testLanguageValueType
{
    PWValueType* type = [PWLanguageValueType valueType];

    NSFormatter* germanFormatter  = [type formatterForContext:self.germanContext];
    NSFormatter* englishFormatter = [type formatterForContext:self.englishContext];
    NSFormatter* importFormatter = [type formatterForContext:self.englishContext options:@{PWValueTypeFormatterForImportExportKey: @YES} object:nil keyPath:nil];

    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:@"de"], @"Deutsch");
    XCTAssertEqualObjects([germanFormatter  stringForObjectValue:@"en"], @"Englisch");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:@"de"], @"German");
    XCTAssertEqualObjects([englishFormatter stringForObjectValue:@"en"], @"English");
    XCTAssertEqualObjects([importFormatter  stringForObjectValue:@"en"], @"en");

    NSString* value;
    XCTAssertTrue([importFormatter getObjectValue:&value forString:@"en" errorDescription:NULL]);
    XCTAssertEqualObjects(value, @"en");

    // TODO: Write tests for NSBundle.mainBundle.localizations related stuff
}

@end
