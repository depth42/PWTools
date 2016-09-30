//
//  NSBundle-PWExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 21.02.06.
//
//

#import "NSBundle-PWExtensions.h"
#import "PWLocality.h"
#import "PWDispatch.h"
#import "NSObject-PWExtensions.h"
#import "NSArray-PWExtensions.h"
#import "NSURL-PWExtensions.h"
#import "PWAsserts.h"
#import "PWTestTesting.h"

#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <mach-o/loader.h>
#include <sys/mman.h>
#include <sys/stat.h>

@implementation NSBundle (PWExtensions)

- (NSSet*)allResourcesForLocalization:(NSString*)language
{
    NSMutableSet* resources = [NSMutableSet set];

    NSFileManager* manager = NSFileManager.defaultManager;
    for(NSString* path in [manager contentsOfDirectoryAtPath:self.resourcePath error:nil])
        if(![path.pathExtension isEqual:@"lproj"])
            [resources addObject:path];
    
    NSString* locName = [language stringByAppendingPathExtension:@"lproj"];
    for(NSString* path in [manager contentsOfDirectoryAtPath:[self.resourcePath stringByAppendingPathComponent:locName] error:nil])
        [resources addObject:[locName stringByAppendingPathComponent:path]];
    return resources;
}

+ (PWDispatchQueue*) dispatchQueue
{
    static PWDispatchQueue* dispatchQueue;
    PWDispatchOnce(^{
        dispatchQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"NSBundle"];
    });
    return dispatchQueue;
}

- (BOOL) isSystemBundle
{
    return [self.bundlePath rangeOfString:@"/System/Library"].location != NSNotFound;
}

static NSSet* nonSystemBundles;

+ (void)flushNonSystemBundles
{
    [self.dispatchQueue asynchronouslyDispatchBlock:^{
        nonSystemBundles = nil;
    }];
}

+ (NSSet*) nonSystemBundles
{
    PWDispatchOnce(^{
        [NSNotificationCenter.defaultCenter addObserverForName:NSBundleDidLoadNotification
                                                          object:nil
                                                   dispatchQueue:self.dispatchQueue
                                                   synchronously:NO
                                                      usingBlock:^(NSNotification* notif) {
                                                          NSBundle* bundle = (NSBundle*)notif.object;
                                                          if (!bundle.isSystemBundle)
                                                              nonSystemBundles = [nonSystemBundles setByAddingObject:bundle];
                                                      }];
    });
    [self.dispatchQueue synchronouslyDispatchBlock:^{
        if (!nonSystemBundles) {
            NSMutableSet* bundles = [NSMutableSet set];
            NSArray* allBundles = [NSBundle.allBundles arrayByAddingObjectsFromArray:NSBundle.allFrameworks];
            for (NSBundle* bundle in allBundles)
                if (!bundle.isSystemBundle)
                    [bundles addObject:bundle];
            nonSystemBundles = [bundles copy];
        }
    }];
    
    return nonSystemBundles;
}

// Unfortunately we need to build a complete localization cache to be able to use multiple languages within a single
// process (as needed by server and web products). The cache is build per bundle and attached to the instance with
// an associated reference.

static NSString* const TableDictsByTableNameKey =  @"tableDictsByTableName";

- (NSString*) localizedStringForKey:(NSString*)key 
                              value:(NSString*)value 
                           language:(NSString*)language
{
    NSParameterAssert (key);
    NSParameterAssert (language);

    return [[self localizerForLanguage:language] localizedStringForKey:key value:value];
}

#pragma mark PWStringLocalizing Protocol

- (NSString*) localizedStringForKey:(NSString*)key value:(NSString*)fallback
{
    return [self.localizer localizedStringForKey:key value:fallback];
}

- (NSString*) localizedString:(NSString*)key
{
    return [self.localizer localizedStringForKey:key value:key];
}

+ (NSString*)applicationName
{
    static NSString* applicationName;
    PWDispatchOnce(^{
        applicationName = NSBundle.mainBundle.infoDictionary[(NSString*)kCFBundleNameKey];
        if(!applicationName)
            applicationName = NSProcessInfo.processInfo.processName;
    });
    return applicationName;
}

+ (NSArray*)URLsToApplicationSupportFolderForDomains:(NSSearchPathDomainMask)domains
{
    NSFileManager* fileManager = NSFileManager.defaultManager;

    NSMutableArray* URLs = [NSMutableArray array];
    NSArray* supportURLs = [fileManager URLsForDirectory:NSApplicationSupportDirectory
                                               inDomains:domains];
    NSString* bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
    if (!bundleIdentifier)  // needed for tests
        bundleIdentifier = self.applicationName;
    for(NSURL* appSupportURL in supportURLs)
    {
        NSURL* URL = [appSupportURL URLByAppendingPathComponent:bundleIdentifier];
        [URLs addObject:URL];
    }
    return URLs;
}

+ (NSComparisonResult) compareVersion:(NSString*)versionA withVersion:(NSString*)versionB
{
    NSArray* segmentsA = [versionA componentsSeparatedByString:@"."];
    NSArray* segmentsB = [versionB componentsSeparatedByString:@"."];
    NSUInteger countA  = segmentsA.count;
    NSUInteger countB  = segmentsB.count;
    NSUInteger count = MIN (countA, countB);
    for (NSUInteger index = 0; index < count; index++)
    {
        NSInteger segmentA = [segmentsA[index] intValue];
        NSInteger segmentB = [segmentsB[index] intValue];
        if (segmentA > segmentB)
            return NSOrderedDescending;
        else if (segmentA < segmentB)
            return NSOrderedAscending;
    }
    if (countA > countB)
        return NSOrderedDescending;
    else if(countA < countB)
        return NSOrderedAscending;
    else
        return NSOrderedSame;   
}

#pragma mark - Localizer

- (NSArray*)availableStringTablesForLanguage:(NSString*)language
{
    NSParameterAssert(language);
    
    if([language isEqualToString:PWLanguageNonLocalized])
        return nil;
    return [[self URLsForResourcesWithExtension:@"strings"
                                   subdirectory:nil
                                   localization:language] map:^(NSURL* tableURL) {
        return tableURL.lastPathComponent.stringByDeletingPathExtension;
    }];
}

- (PWLocalizer*) uncachedLocalizerForLanguages:(NSArray*)languages
{
    NSParameterAssert(languages.count > 0);
    NSParameterAssert(![languages containsObject:PWLanguageNonLocalized] || languages.count == 1);
    
    NSString* language;
    if([languages.firstObject isEqualToString:PWLanguageNonLocalized])
        language = PWLanguageNonLocalized;
    else
    {
        NSArray* localizations = self.localizations;
        PWReleaseAssert(localizations.count > 0, @"Bundle '%@' does not contain any localizations", self);
        language = [NSBundle preferredLocalizationsFromArray:localizations forPreferences:languages].firstObject;
    }
    
    return [PWLocalizer localizerWithTables:[self availableStringTablesForLanguage:language]
                                     bundle:self 
                                   language:language];
}


- (PWLocalizer*) localizerForLanguages:(NSArray*)languages
{    
    NSParameterAssert(languages.count > 0);
    NSParameterAssert(![languages containsObject:PWLanguageNonLocalized] || languages.count == 1);
    
    __block PWLocalizer* localizer;
    static NSString* const AssociationCacheKey = @"net.projectwizards.PWFoundation.localizerByLanguages";
    [self.class.dispatchQueue synchronouslyDispatchBlock:^{
        NSMutableDictionary* localizersByLanguages = [self associatedObjectForKey:AssociationCacheKey];
        if(!localizersByLanguages)
        {
            localizersByLanguages = [NSMutableDictionary dictionary];
            [self setAssociatedObject:localizersByLanguages forKey:AssociationCacheKey copy:NO];
        }
        localizer = localizersByLanguages[languages];
        if (!localizer) 
        {
            localizer = [self uncachedLocalizerForLanguages:languages];
            localizersByLanguages[languages] = localizer;
        }
    }];
    return localizer;    
}

- (PWLocalizer*) localizerForLanguage:(NSString*)language
{
    NSParameterAssert(language);
    return [self localizerForLanguages:@[language]];
}

- (PWLocalizer*) localizer
{
    return [self localizerForLanguages:NSLocale.preferredLanguages];
}

+ (PWLocalizer*) combinedLocalizerForBundles:(id <PWEnumerable>)bundles languages:(NSArray*)languages
{
    NSParameterAssert(bundles.elementCount > 0);
    NSParameterAssert(languages.count > 0);

    NSUInteger count = bundles.elementCount;
    if(count == 1)
    {
        for(NSBundle* iBundle in bundles)
            return [iBundle localizerForLanguages:languages];
        NSAssert(NO, nil);
        return nil;
    }
    else
    {
        NSMutableArray* subLocalizers = [NSMutableArray arrayWithCapacity:count];
        for(NSBundle* iBundle in bundles)
            [subLocalizers addObject:[iBundle localizerForLanguages:languages]];
        return [PWLocalizer localizerWithSubLocalizers:subLocalizers];
    }
}

+ (PWLocalizer*) combinedLocalizerForBundleIdentifiers:(id <PWEnumerable>)identifiers languages:(NSArray*)languages
{
    NSParameterAssert(identifiers.elementCount > 0);
    NSParameterAssert(languages.count > 0);

    NSUInteger count = identifiers.elementCount;
    if(count == 1)
    {
        for(NSString* iIdentifier in identifiers)
        {
            NSBundle* bundle = [NSBundle bundleWithIdentifier:iIdentifier];
            NSAssert(bundle, @"Could not find bundle with identifier %@", iIdentifier);
            return [bundle localizerForLanguages:languages];
        }
        NSAssert(NO, nil);
        return nil;
    }
    else
    {
        NSMutableArray* subLocalizers = [NSMutableArray arrayWithCapacity:count];
        for(NSString* iIdentifier in identifiers)
        {
            NSBundle* bundle = [NSBundle bundleWithIdentifier:iIdentifier];
            NSAssert(bundle, @"Could not find bundle with identifier %@", iIdentifier);
            [subLocalizers addObject:[bundle localizerForLanguages:languages]];
        }
        return [PWLocalizer localizerWithSubLocalizers:subLocalizers];
    }
}

+ (PWLocalizer*) combinedLocalizerForBundleIdentifiers:(id <PWEnumerable>)identifiers
{
    return [self combinedLocalizerForBundleIdentifiers:identifiers languages:NSLocale.preferredLanguages];
}

- (BOOL)containsURL:(NSURL*)URL
{
    NSParameterAssert(URL);
    return [URL hasURLPrefix:self.bundleURL];
}

#pragma mark - Code

- (BOOL)isFromTeamWithID:(NSString*)teamID
{
#if UXTARGET_IOS
    PWASSERT_NOT_AVAILABLE_IOS; // code signing validation makes no sense on iOS
    return YES;
#else
    NSParameterAssert(teamID);

    BOOL result = NO;
    SecStaticCodeRef ref = NULL;

    NSURL* url = [NSURL fileURLWithPath:self.executablePath];
    OSStatus status = SecStaticCodeCreateWithPath((__bridge CFURLRef)url, kSecCSDefaultFlags, &ref);
    if(status == noErr)
    {
        SecRequirementRef req = NULL;
        // Checking only for the team ID in the leaf makes both Mac Developer and Developer ID certificates work.
        NSString* reqStr = [NSString stringWithFormat:@"anchor apple generic and certificate leaf[subject.OU] = \"%@\"", teamID];
        status = SecRequirementCreateWithString((__bridge CFStringRef)reqStr, kSecCSDefaultFlags, &req);
        if (status == noErr)
        {
            if(SecStaticCodeCheckValidity(ref, kSecCSCheckAllArchitectures, req) == noErr)
                result = YES;
            CFRelease(req);
        }
        CFRelease(ref);
    }
    return result;
#endif
}

// Returns the bundle name and the bundle version as a string in the following format "<bundle name>/<bundle version>".
// These values are fetched from the Info.plist inside the bundle.
// For an unknown reason, the underlying NSBundle method does not return any value from the Info.plist if the executable
// is started via a symlink. For these cases you have to compile the Info.plist into the xecutable itself.
// For example add the following options to "Other Linker Flags":
//  -sectcreate __TEXT __info_plist $(SRCROOT)<path to Info.plist>
- (NSString*)bundleNameAndVersionForUserAgentHeader
{
    NSString* name = [self objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey];
    // When running as a framework test from within xcode, the main bundle does not have any name information.
    // In this case, we simply use a generic name.
    if(!name && isRunningTests())
        name = @"xcodetest";
    PWAssert(name.length > 0);

    NSString* version = [self objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    if(!version)
        version = @"1.0";
    PWAssert(version.length > 0);
    
    return [NSString stringWithFormat:@"%@/%@", [name stringByReplacingOccurrencesOfString:@" " withString:@""], version];
}


// An info.plist can be embedded directly into an executable instead of putting it inside a bundle.
// This is really only useful for command-line tools.
// See: https://developer.apple.com/library/mac/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html#//apple_ref/doc/uid/TP40005929-CH4-SW6
// This method returns the info.plist of a bundle _OR_ the embedded info.plist of an executable.
+ (NSDictionary*) infoPlistAtURL:(NSURL*)URL
{
    return CFBridgingRelease(CFBundleCopyInfoDictionaryForURL( (CFURLRef) URL));
}



@end
