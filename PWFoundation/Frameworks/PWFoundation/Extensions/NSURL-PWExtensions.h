//
//  NSURL-PWExtensions.h
//  Merlin
//
//  Created by Frank Illenberger on 7/4/05.
//
//

#import <PWFoundation/PWEnumerable.h>
#import <PWFoundation/PWSDKAvailability.h>

NS_ASSUME_NONNULL_BEGIN

/** Convenience typedef for the frequent case of a completion handler which gets passed on optional error to indicate failure. */
typedef void (^PWCompletionHandlerWithURLAndError) (NSURL*_Nullable url, NSError*_Nullable error);

@interface NSURL (PWExtensions)

/** returns a fileURL pointing to ensured NSTemporaryDirectory/directoryName */
+ (nullable NSURL*)directoryURLInTemporaryDirectoryUsingName:(NSString*)directoryName
                                             replaceExisting:(BOOL)replaceExisting
                                                       error:(NSError**)outError;

/** same as above but with a unique UUID as directoryName */
+ (nullable NSURL*)directoryURLUniqueInTemporaryDirectoryWithError:(NSError**)error;

@property (nonatomic, readonly, copy) NSURL * _Nonnull safeFileURL;

// Returns a new URL with the given components.
// Important: Any parameters must be provided without any URL encodings.
+ (NSURL*)URLWithScheme:(nullable NSString*)scheme
                   user:(nullable NSString*)user
               password:(nullable NSString*)password
                   host:(nullable NSString*)host
                   port:(nullable NSNumber*)port
                   path:(nullable NSString*)path
                  query:(nullable NSString*)query;

@property (nonatomic, readonly, copy) NSURL * _Nonnull URLWithoutCredentials;
@property (nonatomic, readonly, copy) NSURL * _Nonnull URLWithoutCredentialsAndQuery;
- (NSURL*)URLWithUsername:(nullable NSString*)username password:(nullable NSString*)password;
@property (nonatomic, readonly, copy) NSURL * _Nonnull URLWithoutQuery;
@property (nonatomic, readonly, copy) NSURL * _Nonnull URLWithoutPath;
- (NSURL*)URLWithPath:(nullable NSString*)path;
@property (nonatomic, readonly, copy) NSURL * _Nonnull URLWithoutPort;

// Appends 'string' to the end of the URL, whatever that end is (might be a query).
- (NSURL*)URLByAppendingString:(NSString*)string;

// Appends 'string' to the end of the path part of the URL, leaving any query behind it intact.
- (NSURL*)URLByAppendingStringToPath:(NSString*)string;

@property (nonatomic, readonly, copy) NSURL * _Nonnull URLByAppendingResourceForkSpecifier;

- (BOOL)targetsSameResourceAsURL:(NSURL*)URL;
@property (nonatomic, readonly, copy) NSString * _Nullable lastPathComponentWithoutExtension;
- (NSURL*)relativeURLToURL:(NSURL*)endURL;

@property (nonatomic, readonly, copy) NSString * _Nonnull pathWithoutStrippingTrailingSlash;

// Returns -password without URL encoding.
// Important: -password always returns the "raw" value from the URL with percent escapes.
//            In contast: -user never returns the escaped version. This specification is sick!
@property (nonatomic, readonly, copy, nullable) NSString* passwordWithoutEscapes;

@property (nonatomic, readonly, copy, nullable) NSNumber* fileSystemNode;
- (nullable NSNumber*)fileSystemNodeReturningError:(NSError**)outError;

+ (NSString *)IDNEncodedHostname:(NSString *)aHostname;
+ (NSString *)IDNDecodedHostname:(NSString *)anIDNHostname;

@property (nonatomic, readonly, copy) NSDictionary * _Nonnull queryParameters;

- (BOOL)hasURLPrefix:(NSURL*)URL;

// If file exists, checks writability of file. If it does not exist,
// checks writability of parent directory.
@property (nonatomic, getter=isFileWritable, readonly) BOOL fileWritable;

@property (nonatomic, getter=isInTemporaryFolder, readonly) BOOL inTemporaryFolder;
@property (nonatomic, getter=isAccessibleFromSandbox, readonly) BOOL accessibleFromSandbox;
@property (nonatomic, getter=isAccessibleFromSandboxIfRequested, readonly) BOOL accessibleFromSandboxIfRequested;

// Note: always returns NO under iOS.
@property (nonatomic, getter=isInTrash, readonly) BOOL inTrash;

@property (nonatomic, getter=isInUserLibrary, readonly) BOOL inUserLibrary;
@property (nonatomic, getter=isInLocalLibrary, readonly) BOOL inLocalLibrary;

// Handling trailing slashes
@property (nonatomic, readonly) BOOL hasTrailingSlash;
@property (nonatomic, readonly, copy) NSURL * _Nonnull URLByAppendingTrailingSlash;
@property (nonatomic, readonly, copy) NSURL * _Nonnull URLByDeletingTrailingSlash;

+ (NSURL*)realHomeDirectory;
+ (NSURL*)unsandboxedLibraryFolder;

@end

NS_ASSUME_NONNULL_END
