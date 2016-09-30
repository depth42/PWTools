//
//  PWLocalizer.m
//  Merlin
//
//  Created by Andreas Känner on 13.09.2011.
//
//

#import "PWLocalizer.h"
#import "PWLocalizer-Private.h"

#import "PWDispatch.h"
#import "NSString-PWExtensions.h"
#import "NSObject-PWExtensions.h"
#import "NSArray-PWExtensions.h"
#import "NSBundle-PWExtensions.h"
#import "PWLocality.h"
#import "PWLog.h"

@implementation PWLocalizer
{
    NSDictionary* stringsByKey_;
    NSString*     ellipsisSuffix_;
    NSString*     colonSuffix_;
}

@synthesize tables        = tables_;
@synthesize bundle        = bundle_;
@synthesize language      = language_;
@synthesize subLocalizers = subLocalizers_;

- (instancetype)initWithTables:(NSArray*)tables bundle:(NSBundle*)bundle language:(NSString*)language
{
    if(tables.count == 0)
        language = PWLanguageNonLocalized;

    NSAssert(tables.count > 0 || [language isEqual:PWLanguageNonLocalized], nil);
    NSParameterAssert(bundle);
    NSParameterAssert(language);
    
    if(self = [super init])
    {
        bundle_         = bundle;
        tables_         = [tables copy];
        language_       = [language copy];
        stringsByKey_   = [self combinedDictionaryForTables:tables];
    }
    return self;
}

- (instancetype)initWithSubLocalizers:(NSArray*)subLocalizers
{
    NSParameterAssert(subLocalizers.count > 1);
    
    if(self = [super init])
    {
        subLocalizers_ = [subLocalizers copy];
        language_ = [((PWLocalizer*)subLocalizers[0]).language copy];

//#ifndef NDEBUG
//        NSMutableSet* keys = [NSMutableSet set];
//        [self recursivelyValidateUniquenessByAddingToKeys:keys];
//#endif
    }
    return self;
}

+ (PWLocalizer*)localizerWithTables:(NSArray*)tables bundle:(NSBundle*)bundle language:(NSString*)language
{
    return [[self.class alloc] initWithTables:tables bundle:bundle language:language];
}

+ (PWLocalizer*)uncachedLocalizerWithSubLocalizers:(NSArray*)subLocalizers
{
    return [[self.class alloc] initWithSubLocalizers:subLocalizers];
}

+ (PWLocalizer*)localizerWithSubLocalizers:(NSArray*)subLocalizers
{
    NSParameterAssert(subLocalizers.count > 0);
    if(subLocalizers.count == 1)
        return subLocalizers[0];

    __block PWLocalizer* localizer;
    static  NSMutableDictionary* localizerBySubLocalizers;
    [self.dispatchQueue synchronouslyDispatchBlock:^{
        localizer = localizerBySubLocalizers[subLocalizers];
        if (!localizer)
        {
            localizer = [self uncachedLocalizerWithSubLocalizers:subLocalizers];
            if(!localizerBySubLocalizers)
                localizerBySubLocalizers = [NSMutableDictionary dictionary];
            localizerBySubLocalizers[subLocalizers] = localizer;
        }
    }];
    return localizer;
}

+ (PWDispatchQueue*) dispatchQueue
{
    static PWDispatchQueue* dispatchQueue;
    PWDispatchOnce(^{
        dispatchQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWLocalizer"];
    });
    return dispatchQueue;
}

- (NSString*) description
{
    return [NSString stringWithFormat:@"%@ <%p> language: %@ tables: %@ bundle: %@", NSStringFromClass(self.class), self, self.language, tables_, bundle_];
}

- (NSString*) ellipsisSuffix
{
    if(!ellipsisSuffix_)
    {
        NSBundle* pwFoundationBundle = [NSBundle bundleWithIdentifier:@"net.projectwizards.PWFoundation"];
        PWLocalizer* pwFoundationLocalizer = self.bundle == pwFoundationBundle ? self : [pwFoundationBundle localizerForLanguage:language_];
        ellipsisSuffix_ = [pwFoundationLocalizer localizedString:@"ellipsis.suffix"];
    }
    return ellipsisSuffix_;
}

- (NSString*) colonSuffix
{
    if(!colonSuffix_)
    {
        NSBundle* pwFoundationBundle = [NSBundle bundleWithIdentifier:@"net.projectwizards.PWFoundation"];
        PWLocalizer* pwFoundationLocalizer = self.bundle == pwFoundationBundle ? self : [pwFoundationBundle localizerForLanguage:language_];
        colonSuffix_ = [pwFoundationLocalizer localizedString:@"colon.suffix"];
    }
    return colonSuffix_;
}

#pragma mark Loading Tables

- (NSArray*) stringsFilesDescriptionWithKeyFromTables:(NSString*)key
{
    NSParameterAssert(key);
    
    NSMutableArray* result = [NSMutableArray array];
    
    for(NSString* table in tables_)
    {
        NSURL* URL = [bundle_ URLForResource:table
                               withExtension:@"strings"
                                subdirectory:nil
                                localization:language_];
        if(URL)
        {
            NSDictionary* tableDict = [NSDictionary dictionaryWithContentsOfURL:URL];
            NSString* value = tableDict[key];
            if(value)
                [result addObject:[NSString stringWithFormat:@"%@ [%@ / %@] is in %@/…/%@.strings", key, value, language_, bundle_.bundlePath.lastPathComponent, table]];
        }
    }
    return result;
}

// Returns file descriptions (Bundle name / strings file name) for files containing key.
- (NSArray*) stringsFilesDescriptionWithKey:(NSString*)key
{
    if(subLocalizers_)
    {
        NSMutableArray* result = [NSMutableArray array];
        for (PWLocalizer* localizer in subLocalizers_) 
            [result addObjectsFromArray:[localizer stringsFilesDescriptionWithKey:key]];
        return result;
    }
    else
        return [self stringsFilesDescriptionWithKeyFromTables:key];
}

- (void) registerMultipleKey:(NSString*)key
{
#if PWLocalizerRaiseExeptionOnMultipleKeyOccurrence                            
    [NSException raise:@"MultipleKeysException" format:@"The key '%@' occurs multiple times in strings files: %@.", key, [self stringsFilesDescriptionWithKey:key]];                        
#else
    PWLogn(@"\n\t%@", [[self stringsFilesDescriptionWithKey:key] componentsJoinedByString:@"\n\t"]);        
#endif
}

// This method is only used if the localizer contains sublocalizers.
//- (void)recursivelyValidateUniquenessByAddingToKeys:(NSMutableSet*)gatheredKeys
//{
//    NSParameterAssert(gatheredKeys);
//    
//    for(NSString* iKey in stringsByKey_)
//    {
//        if([gatheredKeys containsObject:iKey])
//            [self registerMultipleKey:iKey];
//        [gatheredKeys addObject:iKey];
//    }
//    
//    for(PWLocalizer* iSubLocalized in subLocalizers_)
//        [iSubLocalized recursivelyValidateUniquenessByAddingToKeys:gatheredKeys];
//}

- (NSDictionary*)dictionaryForTable:(NSString*)table
{
    NSParameterAssert(table);
    NSURL* URL = [bundle_ URLForResource:table
                           withExtension:@"strings"
                            subdirectory:nil
                            localization:language_];
    if(!URL)
        [NSException raise:NSInternalInconsistencyException format:@"Localization table '%@' could not be found in bundle '%@'.", table, bundle_];

    NSError* error;
    NSData* data = [NSData dataWithContentsOfURL:URL options:NSDataReadingMappedIfSafe error:&error];
    if(!data)
        [NSException raise:NSInternalInconsistencyException format:@"Error reading localization table %@ error: %@", URL, error];

    NSDictionary* tableDict = [NSPropertyListSerialization propertyListWithData:data
                                                                        options:0
                                                                         format:NULL
                                                                          error:&error];
    if(!tableDict)
        [NSException raise:NSInternalInconsistencyException format:@"Error parsing localization table %@ error: %@", URL, error];
    return tableDict;
}

- (NSDictionary*) combinedDictionaryForTables:(NSArray*)tables
{
    NSMutableDictionary* combinedTableDict = [NSMutableDictionary dictionary];
    
    for(NSString* table in tables_)
    {
        NSDictionary* tableDict = [self dictionaryForTable:table];
        [tableDict enumerateKeysAndObjectsUsingBlock:^(id iKey, id iLocalizedString, BOOL* stop) {
       
#ifndef NDEBUG
            if(combinedTableDict[iKey])
                [self registerMultipleKey:iKey];
#endif
            combinedTableDict[iKey] = iLocalizedString;
        }];
    }
    return combinedTableDict;
}

#pragma mark - Localization

- (NSString*) localizedStringFromTablesForKey:(NSString*)key
{
    NSParameterAssert(key);

    if([key isEqualToString:@":"])
        return self.colonSuffix;
    if([key isEqualToString:@"…"])
        return self.ellipsisSuffix;

    NSString* trialKey = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // ConnectionStatus:

    NSString* localizedString = stringsByKey_[trialKey];
    if(!localizedString)
    {
        // Try to remove a trailing colon if localization is not found and append it again to the localized result.
        BOOL hasColon = [trialKey hasSuffix:@":"];

        // Same with ellipsis / '…'
        BOOL hasEllipsis = [trialKey hasSuffix:@"…"];
        
        if(hasColon || hasEllipsis)
        {
            trialKey = [trialKey substringToIndex:trialKey.length-1];
            localizedString = stringsByKey_[trialKey];
        }
        
        if(!localizedString)
        {
            // Try variants of the case of the starting character
            localizedString = stringsByKey_[trialKey.stringWithLowercaseFirstLetter];
            if(!localizedString)
                localizedString = [stringsByKey_[trialKey.stringWithUppercaseFirstLetter] stringWithLowercaseFirstLetter];
            else
                localizedString = localizedString.stringWithUppercaseFirstLetter;
        }

        if(hasColon)
            localizedString = [localizedString stringByAppendingString:self.colonSuffix];

        if(hasEllipsis)
            localizedString = [localizedString stringByAppendingString:self.ellipsisSuffix];
    }
    return localizedString;
}

- (NSString*) localizedStringFromSubLocalizersForKey:(NSString*)key
{
    NSParameterAssert(key);
    
    for (PWLocalizer* localizer in subLocalizers_) 
    {
        NSString* localizedString = [localizer localizedStringForKey:key];
        if(localizedString)
            return localizedString;
    }
    return nil;
}

- (NSString*) directLocalizedStringForKey:(NSString*)key
{
    NSParameterAssert(key);
    
     return subLocalizers_ ? [self localizedStringFromSubLocalizersForKey:key] : [self localizedStringFromTablesForKey:key];
}


- (NSString*) localizedStringForKey:(NSString*)key
{
    NSParameterAssert(key);
    
    if([language_ isEqual:PWLanguageNonLocalized])
        return key;

    return [self directLocalizedStringForKey:key];
}

- (NSString*) localizedStringForKey:(NSString*)key value:(NSString*)fallback
{
    if(!key)
        return fallback;

    NSString* result = [self directLocalizedStringForKey:key];
    return result ? result : fallback;
}

- (NSString*)localizedString:(NSString*)string
{
    return [self localizedStringForKey:string value:string];
}

- (void)localizeObjects:(NSArray*)objects
{
    for(id object in objects)
        if([object respondsToSelector:@selector(localizeWithLocalizer:)])
            [object localizeWithLocalizer:self];
}

@end
