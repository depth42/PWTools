//
//  NSBundle-PWExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 21.02.06.
//
//

#import <PWFoundation/PWStringLocalizing.h>
#import <PWFoundation/PWLocalizer.h>

@class PWDispatchQueue;
@protocol PWEnumerable;

@interface NSBundle (PWExtensions) < PWStringLocalizing >

// Used to synchronize access to NSBundles. Contention is not expected, therefore a single queue for the bundle class
// and all instances is deemed sufficient.
+ (PWDispatchQueue*) dispatchQueue; // thread safe

+ (NSString*) applicationName;      // thread safe

+ (NSSet*) nonSystemBundles;        // thread safe

// Needs to be manually flushed if bundles which have been added without being loaded should be taken into account
+ (void) flushNonSystemBundles;     // thread safe, non-blocking

+ (NSArray*)URLsToApplicationSupportFolderForDomains:(NSSearchPathDomainMask)domains;       // thread safe
- (NSSet*)allResourcesForLocalization:(NSString*)language;                                  // thread safe

- (PWLocalizer*) localizerForLanguages:(NSArray*)languages;   // cached, thread safe
- (PWLocalizer*) localizerForLanguage:(NSString*)language;    // cached, thread safe
+ (PWLocalizer*) combinedLocalizerForBundles:(id <PWEnumerable>)bundles languages:(NSArray*)languages;                   // uniqued, can be called from any queue
+ (PWLocalizer*) combinedLocalizerForBundleIdentifiers:(id <PWEnumerable>)identifiers languages:(NSArray*)languages;     // uniqued, can be called from any queue
+ (PWLocalizer*) combinedLocalizerForBundleIdentifiers:(id <PWEnumerable>)identifiers;

// Returns the localizer for the preferred language of the current user.
@property (nonatomic, readonly, strong) PWLocalizer *localizer;                                   // cached, thread safe

// Extends NSBundle’s -localizedStringForKey:value:table: by adding language:
- (NSString*) localizedStringForKey:(NSString*)key
                              value:(NSString*)value
                           language:(NSString*)language;    // thread safe

// Compares version strings of the form a.b.c.d with a, b, c, d being signless integer numbers.
+ (NSComparisonResult) compareVersion:(NSString*)versionA withVersion:(NSString*)versionB;

@property (nonatomic, getter=isSystemBundle, readonly) BOOL systemBundle;

- (BOOL)isFromTeamWithID:(NSString*)teamID;

- (BOOL)containsURL:(NSURL*)URL;

// Returns the bundle name and the bundle version as a string in the following format "<bundle name>/<bundle version>".
// These values are fetched from the Info.plist inside the bundle.
// For an unknown reason, the underlying NSBundle method does not return any value from the Info.plist if the executable
// is started via a symlink. For these cases you have to compile the Info.plist into the xecutable itself.
// For example add the following options to "Other Linker Flags":
//  -sectcreate __TEXT __info_plist $(SRCROOT)<path to Info.plist>
@property (nonatomic, readonly, copy) NSString *bundleNameAndVersionForUserAgentHeader;

// The info.plist can be embedded directly into an executable instead of putting it inside a bundle.
// This is really only useful for command-line tools.
// See: https://developer.apple.com/library/mac/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html#//apple_ref/doc/uid/TP40005929-CH4-SW6
// This method returns the info.plist of a bundle _OR_ the embedded info.plist of an executable.
+ (NSDictionary*) infoPlistAtURL:(NSURL*)URL;

@end
