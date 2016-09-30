//
//  PWEnumFormatter.m
//  PWFoundation
//
//  Created by Frank Illenberger on 03.03.10.
//
//

#import "PWEnumFormatter.h"
#import "PWLocality.h"
#import "NSArray-PWExtensions.h"
#import "NSBundle-PWExtensions.h"
#import "NSObject-PWExtensions.h"
#import "NSString-PWExtensions.h"

@implementation PWEnumFormatter
{
    NSString*       _localizedNilValueName;
    NSDictionary*   _localizedNameByValue;
    NSDictionary*   _unlocalizedNameByValue;
}

- (NSString*)localizedString:(NSString*)key
{
    if(!_localizer)
        return key;

    NSString* result;
    if(key.length > 0 && _localizationKeyPrefix)
    {
        NSString* prefixedKey = [_localizationKeyPrefix stringByAppendingString:key];
        result = [_localizer localizedStringForKey:prefixedKey value:nil];
        if(!result)
            result = [_localizer localizedString:key];
    }
    else
        result = [_localizer localizedString:key];
    return result;
}

- (NSString*)stringForObjectValue:(id)anObject
{
    NSString* string;
    if(anObject)
    {
        NSString* name = _localizedNameByValue[anObject]; 
        string = name ? name :  [anObject description];
    }
    else
        string = _localizedNilValueName;
    if(_capitalizesFirstCharacter)
        string = string.stringWithUppercaseFirstLetter;
    return string;
}

- (BOOL)getObjectValue:(id*)anObject 
             forString:(NSString*)string
      errorDescription:(NSString**)error
{
    NSParameterAssert(anObject);

    if(_capitalizesFirstCharacter)
        string = string.stringWithLowercaseFirstLetter;

    if(string.length == 0 || [_localizedNilValueName isEqualToString:string])
    {
        *anObject = nil;
        return YES;
    }
    
    id value = [_localizedNameByValue allKeysForObject:string].firstObject;
    if(value)
    {
        *anObject = value;
        return YES;
    }
    
    value = [_unlocalizedNameByValue allKeysForObject:string].firstObject;
    if(value)
    {
        *anObject = value;
        return YES;
    }
    
    if([_unlocalizedNilValueName isEqualToString:string])
    {
        *anObject = nil;
        return YES;
    }

    if(error)
        *error = [NSString stringWithFormat:@"PWEnumFormatter error: Unknown enum value '%@'. Example values: %@",
                  string, [_localizedNameByValue.allValues componentsJoinedByString:@", "]];

    return NO;
}

- (instancetype) initWithLocalizer:(PWLocalizer*)localizer
                  values:(NSArray*)theValues      // hashable, copyable,
        unlocalizedNames:(NSArray*)names         // NSString, same count as values
 unlocalizedNilValueName:(NSString*)unlocalizedNilName
   localizationKeyPrefix:(NSString*)localizationKeyPrefix
{
    NSParameterAssert(theValues.count == names.count);
    if(self = [super init])
    {
        _localizer              = localizer;
        _values                 = [theValues copy];
        _unlocalizedNames       = [names copy];
        _localizationKeyPrefix  = [localizationKeyPrefix copy];
        
        NSMutableDictionary* nameByValue = [NSMutableDictionary dictionary];
        NSMutableDictionary* unlocNameByValue = [NSMutableDictionary dictionary];
        [_values enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {
            id name = names[idx];
            NSCAssert([name isKindOfClass:NSString.class], nil);
            nameByValue[value] = [self localizedString:name];
            unlocNameByValue[value] = name;
        }];
        
        _localizedNameByValue       = [nameByValue copy];
        _unlocalizedNameByValue     = [unlocNameByValue copy];
        _unlocalizedNilValueName    = unlocalizedNilName ? [unlocalizedNilName copy] : @"";
        _localizedNilValueName      = _unlocalizedNilValueName ? [self localizedString:_unlocalizedNilValueName] : nil;
    }
    return self;
}

- (instancetype) initWithLocality:(PWLocality*)locality
                 bundle:(NSBundle*)bundle
                 values:(NSArray*)values
       unlocalizedNames:(NSArray*)names
unlocalizedNilValueName:(NSString*)unlocalizedNilName
  localizationKeyPrefix:(NSString*)localizationKeyPrefix
{
    NSString* language = locality.language;
    PWLocalizer* localizer;
    if(language && ![language isEqualToString:PWLanguageNonLocalized])
        localizer = [bundle ? bundle : NSBundle.mainBundle localizerForLanguage:language];

    return [self initWithLocalizer:localizer
                            values:values
                  unlocalizedNames:names
           unlocalizedNilValueName:unlocalizedNilName
             localizationKeyPrefix:localizationKeyPrefix];
}
@end
