//
//  PWBoolFormatter.m
//  PWFoundation
//
//  Created by Frank Illenberger on 02.03.10.
//
//

#import "PWBoolFormatter.h"
#import "NSBundle-PWExtensions.h"
#import "PWLocality.h"
#import "NSArray-PWExtensions.h"
#import "NSString-PWExtensions.h"
#import "PWTypes.h"

@implementation PWBoolFormatter
{
    NSBundle* _bundle;
}

- (id)init
{
    if(self = [super init])
    {
        _bundle = [NSBundle bundleForClass:self.class];
    }
    return self;
}

- (BOOL)localizes
{
    return ![_locality.language isEqualToString:PWLanguageNonLocalized];
}

- (NSString*)mixedKey
{
    return self.localizes ? @"valueType.bool.mixed" : @"mixed";
}

- (NSString*)localizedString:(NSString*)key
{
    NSString* language = _locality.language;
    if(!language)
        language = _bundle.preferredLocalizations.firstObject;

    return [[_bundle localizerForLanguage:language] localizedStringForKey:key value:key];
}

- (NSString*)stringForObjectValue:(id)anObject
{
    NSParameterAssert(!anObject || [anObject isKindOfClass:NSNumber.class]);
    
    NSNumber* number = ((NSNumber*)anObject);
    if(!number)
        return nil;

    NSString* key;
    NSString* trueString  = _showsYesAndNo? @"yes" : @"true";
    NSString* falseString = _showsYesAndNo? @"no"  : @"false";
    if(_allowsMixed && number.intValue == PWBoolMixed)
        key = self.mixedKey;
    else
        key = number.boolValue ? trueString : falseString;
    return [self localizedString:key];
}

- (BOOL)getObjectValue:(id*)anObject 
             forString:(NSString*)string
      errorDescription:(NSString**)error
{
    NSParameterAssert(anObject);
    
    string = string.lowercaseString.stringByTrimmingSpaces;
    if(string.length > 0)
    {
        if([[self localizedString:@"yes"] hasPrefix:string] || [[self localizedString:@"true"] hasPrefix:string] || [string isEqualToString:@"1"])
            *anObject = @(YES);
        else if([[self localizedString:@"no"] hasPrefix:string] || [[self localizedString:@"false"] hasPrefix:string] || [string isEqualToString:@"0"])
            *anObject = @(NO);
        else if(_allowsMixed && [[self localizedString:self.mixedKey] hasPrefix:string])
            *anObject = @(PWBoolMixed);
        else
            *anObject = @(NO);
    }
    else
        *anObject = nil;
    return YES;
}

@end
