//
//  NSURL-PWExtensions.m
//  Merlin
//
//  Created by Frank Illenberger on 7/4/05.
//
//

#import "NSURL-PWExtensions.h"
#import "NSString-PWExtensions.h"
#import "NSArray-PWExtensions.h"
#import "NSObject-PWExtensions.h"
#import "NSError-PWExtensions.h"
#import "PWErrors.h"
#import <sys/paths.h>
#import <sys/stat.h>
#import <sys/types.h>
#import <unistd.h>
#import <pwd.h>

#if UXTARGET_IOS
#import <MobileCoreServices/MobileCoreServices.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@implementation NSURL (PWExtensions)

- (nullable NSString*)passwordWithoutEscapes
{
    return self.password.stringByRemovingPercentEncoding;
}

- (NSURL*)safeFileURL
{
    NSInteger numberWithName = 1;
    BOOL isDir;
    NSString* creationPath = self.path;
    NSString* safePath = creationPath;
    NSFileManager* manager = NSFileManager.defaultManager;
    if([manager fileExistsAtPath:safePath isDirectory:&isDir])
        while ([manager fileExistsAtPath:safePath isDirectory:&isDir])
            safePath = [NSString stringWithFormat:@"%@ %ld.%@", creationPath.stringByDeletingPathExtension, (long)numberWithName++, creationPath.pathExtension];
    return [NSURL fileURLWithPath:safePath];
}

+ (NSURL*)URLWithScheme:(nullable NSString*)scheme
                   user:(nullable NSString*)user
               password:(nullable NSString*)password
                   host:(nullable NSString*)host
                   port:(nullable NSNumber*)port
                   path:(nullable NSString*)path
                  query:(nullable NSString*)query
{
    NSMutableString* urlString = [NSMutableString string];
    if(scheme)
    {
        [urlString appendString:scheme];
        [urlString appendString:@"://"];
    }
    if(user || password)
    {
        if(user) {
            NSString* escapedUsername = [user stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLUserAllowedCharacterSet];
            [urlString appendString:escapedUsername];
        }
        if(password)
        {
            NSString* escapedPassword = [password stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPasswordAllowedCharacterSet];
            [urlString appendString:@":"];
            [urlString appendString:escapedPassword];
        }
        [urlString appendString:@"@"];
    }
    if(host)
    {
        host = host.URLHostByAddingRequiredBrackets;
        NSString* escapedHost = [host stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLHostAllowedCharacterSet];
        [urlString appendString:escapedHost];
        if(port)
            [urlString appendFormat:@":%@", port];
    }
    if(path)
    {
        if(![path hasPrefix:@"/"])
            [urlString appendString:@"/"];
        NSString* escapedPath = [path stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
        [urlString appendString:escapedPath];
    }
    if(query)
    {
        [urlString appendString:@"?"];
        [urlString appendString:query];
    }
    NSURL* URL = [NSURL URLWithString:urlString];

    return URL;
}

- (NSURL*)URLWithoutCredentials
{
    return [NSURL URLWithScheme:self.scheme user:nil password:nil host:self.host port:self.port path:self.path query:self.query];
}

- (NSURL*)URLWithoutCredentialsAndQuery
{
    return [NSURL URLWithScheme:self.scheme user:nil password:nil host:self.host port:self.port path:self.path query:nil];
}

- (NSURL*)URLWithoutQuery
{
    return [NSURL URLWithScheme:self.scheme user:self.user password:self.passwordWithoutEscapes host:self.host port:self.port path:self.path query:nil];
}

- (NSURL*)URLWithoutPath
{
    return [NSURL URLWithScheme:self.scheme user:self.user password:self.passwordWithoutEscapes host:self.host port:self.port path:nil query:nil];
}

- (NSURL*)URLWithUsername:(nullable NSString*)username password:(nullable NSString*)password
{
    return [NSURL URLWithScheme:self.scheme user:username password:password host:self.host port:self.port path:self.path query:self.query];
}

- (NSURL*)URLWithPath:(nullable NSString*)path
{
    return [NSURL URLWithScheme:self.scheme user:self.user password:self.passwordWithoutEscapes host:self.host port:self.port path:path query:self.query];
}

- (NSURL*)URLWithoutPort
{
    return [NSURL URLWithScheme:self.scheme user:self.user password:self.passwordWithoutEscapes host:self.host port:nil path:self.path query:self.query];
}

- (NSURL*)URLByAppendingString:(NSString*)string
{
    NSParameterAssert (string);
    return [NSURL URLWithString:[self.description stringByAppendingString:string]];
}

- (NSURL*)URLByAppendingStringToPath:(NSString*)string
{
    NSParameterAssert (string);
    NSString* newLastPathComponent = [self.lastPathComponent stringByAppendingString:string];
    return [self.URLByDeletingLastPathComponent URLByAppendingPathComponent:newLastPathComponent];
}

- (NSURL*)URLByAppendingResourceForkSpecifier
{
    return [self URLByAppendingStringToPath:@_PATH_RSRCFORKSPEC];  
}

- (BOOL)targetsSameResourceAsURL:(NSURL*)URL
{
    return [self isEqual:URL]
    || [self.URLWithoutCredentialsAndQuery.URLByResolvingSymlinksInPath isEqual:URL.URLWithoutCredentialsAndQuery.URLByResolvingSymlinksInPath] 
    || (self.isFileURL && URL.isFileURL && [URL.path isEqual:self.path]);
}

- (nullable NSString*) lastPathComponentWithoutExtension
{
    NSString* result = self.lastPathComponent;
    if (result) {
        NSString* extension = result.pathExtension;
        if (extension.length > 0)
            result = [result substringToIndex:result.length - extension.length - 1];
    }
    return result;
}

- (NSURL*)relativeURLToURL:(NSURL*)endURL
{
    NSParameterAssert(endURL);
    
    if(![self isHostEqualToHost:endURL.host] || !PWEqualObjects(self.scheme, endURL.scheme) || !PWEqualObjects(self.port, endURL.port))
        return endURL;
    
    NSString* relativePath = [self.path relativePathToPath:endURL.path];
    NSString* encodedPath = [relativePath stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLPathAllowedCharacterSet];
    NSURL* result = [NSURL URLWithString:encodedPath relativeToURL:self];
    return result;
}

// Checks wether the host of the receiver and the provided host do match.
// If either one of the the two hosts is nil it is assumed that it means
// "localhost".
// This check is necessary since some file URLs do contain the host and
// others do not. In order to derive a relative URL with -relativeURLToURL:
// this special check is necessary.
- (BOOL)isHostEqualToHost:(NSString*)otherHost
{
    NSString* host = self.host;
    
    if(!host && !otherHost)
        return YES;
    
    if(!host)
        host = @"localhost";
    
    if(!otherHost)
        otherHost = @"localhost";
    
    return PWEqualObjects(host, otherHost);
}

- (NSString*)pathWithoutStrippingTrailingSlash
{
    return (__bridge_transfer NSString*)(CFURLCopyPath((__bridge CFURLRef)(self)));
}

- (nullable NSNumber*)fileSystemNode
{
    if(self.isFileURL)
    {
        struct stat buf;
        if(stat(self.absoluteURL.path.fileSystemRepresentation, &buf) == 0)
            return @(buf.st_ino);
        NSLog (@"Could not get fileSystemNode, stat failed with %i", errno);
    }
    return nil;
}

- (nullable NSNumber*)fileSystemNodeReturningError:(NSError**)outError
{
    if(!self.isFileURL)
    {
        if (outError)
            *outError = [NSError errorWithDomain:PWErrorDomain
                                            code:PWURLSchemeError
                             localizationContext:nil
                                          format:@"Not a file URL: %@", self];
        return nil;
    }

    struct stat buf;
    if(stat(self.absoluteURL.path.fileSystemRepresentation, &buf) != 0)
    {
        if (outError)
            *outError = [NSError errorWithDomain:NSPOSIXErrorDomain
                                            code:errno
                             localizationContext:nil
                                          format:@"Could not get fileSystemNode for %@", self];
        return nil;
    }
    
    return @(buf.st_ino);
}

#pragma mark Punycode

#ifndef MAX_HOSTNAME_LEN
#ifdef NI_MAXHOST
#define MAX_HOSTNAME_LEN NI_MAXHOST
#else
#define MAX_HOSTNAME_LEN 1024
#endif
#endif

// Adapted from OmniNetworking framework
// Copyright 1997-2005 Omni Development, Inc.  All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

// Punycode is defined in RFC 3492

#define ACEPrefix @"xn--"   // Prefix for encoded labels, defined in RFC3490 [5]

#define encode_character(c) (c) < 26 ? (c) + 'a' : (c) - 26 + '0'

static const short punycodeDigitValue[0x7B] = {
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 0x00 - 0x0F
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 0x10 - 0x1F
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, // 0x20 - 0x2F
    26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, -1, -1, -1, // 0x30 - 0x3F
    -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, // 0x40 - 0x4F
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -1, -1, -1, -1, -1, // 0x50 - 0x5F
    -1,  0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, 13, 14, // 0x60 - 0x6F
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25                      // 0x70 - 0x7A
};


static int adaptPunycodeDelta(int delta, int number, BOOL firstTime)
{
    int power;

    delta = firstTime ? delta / 700 : delta / 2;
    delta += delta / number;

    for (power = 0; delta > (35 * 26) / 2; power += 36)
        delta /= 35;
    return power + (35 + 1) * delta / (delta + 38);
}

/* Minimal validity checking. This should be elaborated to include the full IDN stringprep profile. */
static BOOL validIDNCodeValue(unsigned codepoint)
{
    /* Valid Unicode, non-basic codepoint? (implied by rfc3492) */
    if (codepoint < 0x9F || codepoint > 0x10FFFF)
        return NO;

    /* Some prohibited values from rfc3454 referenced by rfc3491[5] */
    if (codepoint == 0x00A0 ||
        (codepoint >= 0x2000 && codepoint <= 0x200D) ||
        codepoint == 0x202F || codepoint == 0xFEFF ||
        ( codepoint >= 0xFFF9 && codepoint <= 0xFFFF ))
        return NO; /* Miscellaneous whitespace & non-printing characters */

    int plane = ( codepoint & ~(0xFFFF) );

    if (plane == 0x0F0000 || plane == 0x100000 ||
        (codepoint >= 0xE000 && codepoint <= 0xF8FF))
        return NO;  /* Private use areas */

    if ((codepoint & 0xFFFE) == 0xFFFE ||
        (codepoint >= 0xD800 && codepoint <= 0xDFFF) ||
        (codepoint >= 0xFDD0 && codepoint <= 0xFDEF))
        return NO; /* Various non-character code points */

    /* end of gauntlet */
    return YES;
}

+ (NSString *)_punycodeEncode:(NSString *)aString;
{
    // setup buffers
    char outputBuffer[MAX_HOSTNAME_LEN];
    size_t stringLength = aString.length;
    unichar *inputBuffer = alloca(stringLength * sizeof(unichar));
    unichar *inputPtr, *inputEnd = inputBuffer + stringLength;
    char *outputEnd = outputBuffer + MAX_HOSTNAME_LEN;
    char *outputPtr = outputBuffer;

    // check once for hostname too long here and just refuse to encode if it is (this handles it if all ASCII)
    // there are additional checks for running over the buffer during the encoding loop
    if (stringLength > MAX_HOSTNAME_LEN)
        return aString;

    [aString getCharacters:inputBuffer];

    // handle ASCII characters
    for (inputPtr = inputBuffer; inputPtr < inputEnd; inputPtr++) {
        if (*inputPtr < 0x80)
            *outputPtr++ = *inputPtr;
    }
    unsigned int handled = (unsigned int)(outputPtr - outputBuffer);

    if (handled == stringLength)
        return aString;

    // add dash separator
    if (handled > 0 && outputPtr < outputEnd)
        *outputPtr++ = '-';

    // encode the rest
    int n = 0x80;
    int delta = 0;
    int bias = 72;
    BOOL firstTime = YES;

    while (handled < stringLength) {
        unichar max = (unichar)-1;
        for (inputPtr = inputBuffer; inputPtr < inputEnd; inputPtr++) {
            if (*inputPtr >= n && *inputPtr < max)
                max = *inputPtr;
        }

        delta += (max - n) * (handled + 1);
        n = max;

        for (inputPtr = inputBuffer; inputPtr < inputEnd; inputPtr++) {
            if (*inputPtr < n)
                delta++;
            else if (*inputPtr == n) {
                int oldDelta = delta;
                int power = 36;

                // NSLog(@"encode: delta=%d pos=%d bias=%d codepoint=%05x", delta, inputPtr-inputBuffer, bias, *inputPtr);

                while (1) {
                    int t;
                    if (power <= bias)
                        t = 1;
                    else if (power >= bias + 26)
                        t = 26;
                    else
                        t = power - bias;
                    if (delta < t)
                        break;
                    if (outputPtr >= outputEnd)
                        return aString;
                    *outputPtr++ = encode_character(t + (delta - t) % (36 - t));
                    delta = (delta - t) / (36 - t);
                    power += 36;
                }

                if (outputPtr >= outputEnd)
                    return aString;
                *outputPtr++ = encode_character(delta);
                bias = adaptPunycodeDelta(oldDelta, ++handled, firstTime);
                firstTime = NO;
                delta = 0;
            }
        }
        delta++;
        n++;
    }
    if (outputPtr >= outputEnd)
        return aString;
    *outputPtr = '\0';
#ifdef DEBUG_toon
    NSLog(@"Punycode encoded \"%@\" into \"%s\"", aString, outputBuffer);
#endif
    return [ACEPrefix stringByAppendingString:@(outputBuffer)];
}

+ (NSString *)_punycodeDecode:(NSString *)aString;
{
    NSMutableString *decoded;
    NSRange deltas;
    unsigned int *delta;
    unsigned deltaCount, deltaIndex;
    NSUInteger labelLength;
    const unsigned acePrefixLength = 4;
    {
        /* Check that the string has the IDNA ACE prefix. Most strings won't. */
        labelLength = aString.length;
        if (labelLength < acePrefixLength ||
            ([aString compare:ACEPrefix options:NSCaseInsensitiveSearch range:(NSRange){0,acePrefixLength}] != NSOrderedSame))
            return aString;

        /* Also, any valid encoded string will be all-ASCII */
        if (![aString canBeConvertedToEncoding:NSASCIIStringEncoding])
            return aString;

        /* Find the delimiter that marks the end of the basic-code-points section. */
        NSRange delimiter = [aString rangeOfString:@"-"
                                           options:NSBackwardsSearch
                                             range:(NSRange){acePrefixLength, labelLength-acePrefixLength}];
        if (delimiter.length > 0) {
            decoded = [[aString substringWithRange:(NSRange){acePrefixLength, delimiter.location - acePrefixLength}] mutableCopy];
            deltas = (NSRange){NSMaxRange(delimiter), labelLength - NSMaxRange(delimiter)};
        } else {
            /* No delimiter means no basic code point section: it's all encoded deltas (RFC3492 [3.1]) */
            decoded = [[NSMutableString alloc] init];
            deltas = (NSRange){acePrefixLength, labelLength - acePrefixLength};
        }

        /* If there aren't any deltas, it's not a valid IDN label, because you're not supposed to encode something that didn't need to be encoded. */
        if (deltas.length == 0) {
            return aString;
        }

        unsigned int decodedLabelLength = (unsigned)decoded.length;

        /* Convert the variable-length-integers in the deltas section into machine representation */
        {
            unichar *enc;
            unsigned i, bias, value, weight, position;
            BOOL reset;
            const int base = 36, tmin = 1, tmax = 26;

            enc = malloc(sizeof(*enc) * deltas.length);  // code points from encoded string
            delta = malloc(sizeof(*delta) * deltas.length); // upper bound on number of decoded integers
            deltaCount = 0;
            bias = 72;
            reset = YES;
            value = weight = position = 0;

            [aString getCharacters:enc range:deltas];
            for(i = 0; i < deltas.length; i++) {
                int digit, threshold;

                if (reset) {
                    value = 0;
                    weight = 1;
                    position = 0;
                    reset = NO;
                }

                if (enc[i] <= 0x7A)
                    digit = punycodeDigitValue[enc[i]];
                else {
                    free(enc);
                    goto fail;
                }
                if (digit < 0) { // unassigned value
                    free(enc);
                    goto fail;
                }

                value += weight * digit;
                threshold = base * (position+1) - bias;

                // clamp to tmin=1 tmax=26 (rfc3492 [5])
                threshold = MIN(threshold, tmax);
                threshold = MAX(threshold, tmin);

                if (digit < threshold) {
                    delta[deltaCount++] = value;
                    // NSLog(@"decode: delta[%d]=%d bias=%d from=%@", deltaCount-1, value, bias, [aString substringWithRange:(NSRange){deltas.location + i - position, position+1}]);
                    bias = adaptPunycodeDelta(value, deltaCount + decodedLabelLength, (deltaCount==1) ? YES : NO);
                    reset = YES;
                } else {
                    weight *= (base - threshold);
                    position ++;
                }
            }

            free(enc);

            if (!reset) {
                /* The deltas section ended in the middle of an integer: something's wrong */
                goto fail;
            }

            /* deltas[] now holds deltaCount integers */
        }

        /* now use the decoded integers to insert characters into the decoded string */
        {
            unsigned position, codeValue;
            unichar ch[1];

            position = 0;
            codeValue = 0x80;

            for (deltaIndex = 0; deltaIndex < deltaCount; deltaIndex ++) {
                position += delta[deltaIndex];

                codeValue += ( position / (decodedLabelLength + 1) );
                position = ( position % (decodedLabelLength + 1) );

                if (!validIDNCodeValue(codeValue))
                    goto fail;

                /* TODO: This will misbehave for code points greater than 0x0FFFF, because NSString uses a 16-bit encoding internally; the position values will be off by one afterwards [actually, we'll just get bad results because I'm using initWithCharacters:length: (BMP-only) instead of initWithCharacter: (all planes but only exists in OmniFoundation)] */
                ch[0] = codeValue;
                NSString *insertion = [[NSString alloc] initWithCharacters:ch length:1];
                [decoded replaceCharactersInRange:(NSRange){position, 0} withString:insertion];
                
                position ++;
                decodedLabelLength ++;
            }
        }
        
        if (decoded.length != decodedLabelLength)
            goto fail;
        
        free(delta);
        
        NSString *normalized = decoded.precomposedStringWithCompatibilityMapping;  // Applies normalization KC
        if ([normalized compare:decoded options:NSLiteralSearch] != NSOrderedSame) {
            // Decoded string was not normalized, therefore could not have been the result of decoding a correctly encoded IDN.
            return aString;
        } else {
            return normalized;
        }
    }
fail:
    free(delta);
    return aString;
}

+ (NSString *)IDNEncodedHostname:(NSString *)aHostname;
{
    if ([aHostname canBeConvertedToEncoding:NSASCIIStringEncoding])
        return aHostname;

    NSArray *parts = [aHostname componentsSeparatedByString:@"."];
    NSMutableArray *encodedParts = [NSMutableArray array];
    NSUInteger partIndex, partCount = parts.count;

    for (partIndex = 0; partIndex < partCount; partIndex++)
        [encodedParts addObject:[self _punycodeEncode:[parts[partIndex] precomposedStringWithCompatibilityMapping]]];
    return [encodedParts componentsJoinedByString:@"."];
}

+ (NSString *)IDNDecodedHostname:(NSString *)anIDNHostname;
{
    NSArray *labels = [anIDNHostname componentsSeparatedByString:@"."];
    NSMutableArray *decodedLabels;
    NSUInteger labelIndex, labelCount;
    BOOL wasEncoded;

    labelCount = labels.count;
    decodedLabels = [[NSMutableArray alloc] initWithCapacity:labelCount];
    wasEncoded = NO;

    for (labelIndex = 0; labelIndex < labelCount; labelIndex++) {
        NSString *label, *decodedLabel;

        label = labels[labelIndex];
        decodedLabel = [self _punycodeDecode:label];
        if (!wasEncoded && ![label isEqualToString:decodedLabel])
            wasEncoded = YES;
        [decodedLabels addObject:decodedLabel];
    }

    if (wasEncoded) {
        NSString *result = [decodedLabels componentsJoinedByString:@"."];
        return result;
    } else {
        /* This is by far the most common case. */
        return anIDNHostname;
    }
}

- (NSDictionary*)queryParameters
{
    NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
    
    NSArray* keyValuePairs = [self.query componentsSeparatedByString:@"&"];
    for(NSString* keyValuePair in keyValuePairs)
    {
        NSArray* parts = [keyValuePair componentsSeparatedByString:@"="];
        NSAssert(parts.count >= 1 && parts.count <= 2, nil);
        NSString* key = parts[0];
        NSString* value = parts.count == 2 ? parts[1] : NSNull.null;
        key = key.stringByRemovingPercentEncoding;
        value = value.stringByRemovingPercentEncoding;
        [parameters setValue:value forKey:key];
    }
    
    return parameters;
}

- (BOOL)hasURLPrefix:(NSURL*)URL
{
    NSParameterAssert(URL.isFileURL && self.isFileURL);
    NSString* URLPath = URL.URLByResolvingSymlinksInPath.URLByStandardizingPath.pathWithoutStrippingTrailingSlash;
    NSString* path = self.URLByResolvingSymlinksInPath.URLByStandardizingPath.pathWithoutStrippingTrailingSlash;
    return [path hasPrefix:URLPath];
}

- (BOOL)isFileWritable
{
    NSFileManager* manager = NSFileManager.defaultManager;
    NSString* path = self.path;
    NSString* checkPath;
    if([manager fileExistsAtPath:path])
        checkPath = path;
    else
        checkPath = path.stringByDeletingLastPathComponent;
    if(![manager isWritableFileAtPath:checkPath])
        return NO;

    if([path isEqualToString:@"/"])
        return YES;

    // If a directory is set to be user immutable, its directly contained
    // files and directories are not writable (Attention: This is only
    // valid for the first level, this is not recursive!)
    // Testing -isWritableFileAtPath: however returns YES for contained
    // files so we addd an extra check for this case.
    NSNumber* locked;
    if(![self.URLByDeletingLastPathComponent getResourceValue:&locked
                                                         forKey:NSURLIsUserImmutableKey
                                                          error:NULL])
        return NO;

    return !locked.boolValue;
}

+ (nullable NSURL*)directoryURLInTemporaryDirectoryUsingName:(NSString*)directoryName
                                             replaceExisting:(BOOL)replaceExisting
                                                       error:(NSError**)outError
{
    PWParameterAssert(directoryName);

    NSURL* resultURL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:directoryName];
    
    if ([NSFileManager.defaultManager fileExistsAtPath:resultURL.path])
    {
        if (![NSFileManager.defaultManager removeItemAtURL:resultURL error:outError])
        {
            return PWErrorRefEnsureOrigin(outError, directoryName, nil);
        }
    }
    
    if (![NSFileManager.defaultManager createDirectoryAtURL:resultURL
                                          withIntermediateDirectories:YES
                                                           attributes:nil
                                                                error:outError])
    {
        return PWErrorRefEnsureOrigin(outError, resultURL, nil);
    }

    return resultURL;
}

+ (nullable NSURL*)directoryURLUniqueInTemporaryDirectoryWithError:(NSError**)error
{
    return [NSURL directoryURLInTemporaryDirectoryUsingName:NSUUID.UUID.UUIDString
                                            replaceExisting:NO // should never be relevant with a UUID name
                                                      error:error];
}

- (BOOL)isInTemporaryFolder
{
    return [self hasURLPrefix:[NSURL fileURLWithPath:NSTemporaryDirectory()]];
}

- (BOOL)isAccessibleFromSandbox
{
    return self.isFileURL && access( self.path.fileSystemRepresentation, R_OK) == 0;
}

- (BOOL)isAccessibleFromSandboxIfRequested
{
    if(self.isAccessibleFromSandbox)
        return YES;
    if([self startAccessingSecurityScopedResource])
    {
        [self stopAccessingSecurityScopedResource];
        return YES;
    }
    return NO;
}

- (BOOL)isInTrash
{
#if UXTARGET_IOS
    return NO;
#else
    NSFileManager* fm = NSFileManager.defaultManager;
    NSURL* trashURL = [fm URLForDirectory:NSTrashDirectory
                                 inDomain:NSUserDomainMask
                        appropriateForURL:self
                                   create:NO
                                    error:NULL];
    return trashURL && [self hasURLPrefix:trashURL];
#endif
}

+ (NSURL*)realHomeDirectory
{
    struct passwd *pw = getpwuid(getuid());
    return [NSURL fileURLWithPath:@(pw->pw_dir)];
}

+ (NSURL*)unsandboxedLibraryFolder
{
    return [self.realHomeDirectory URLByAppendingPathComponent:@"Library"];
}

- (BOOL)isInUserLibrary
{
    NSFileManager* fm = NSFileManager.defaultManager;
    NSURL* containerLibraryURL = [fm URLForDirectory:NSLibraryDirectory
                                            inDomain:NSUserDomainMask
                                   appropriateForURL:self
                                              create:NO
                                               error:NULL];
    if(containerLibraryURL && [self hasURLPrefix:containerLibraryURL])
        return YES;

    // For sandboxed applications we also exclude the general Library
    NSURL* homeLibraryURL = self.class.unsandboxedLibraryFolder;
    return homeLibraryURL && [self hasURLPrefix:homeLibraryURL];
}

- (BOOL)isInLocalLibrary
{
    NSFileManager* fm = NSFileManager.defaultManager;
    NSURL* libraryURL = [fm URLForDirectory:NSLibraryDirectory
                                   inDomain:NSLocalDomainMask
                          appropriateForURL:self
                                     create:NO
                                      error:NULL];
    return libraryURL && [self hasURLPrefix:libraryURL];
}

- (BOOL)hasTrailingSlash
{
	PWParameterAssert(self.isFileURL);
	return [self.absoluteString hasSuffix:@"/"];
}

- (NSURL*)URLByAppendingTrailingSlash
{
	PWParameterAssert(self.isFileURL);
	NSURL* url = self;
	if (!self.hasTrailingSlash)
        url = [NSURL URLWithString:[self.absoluteString stringByAppendingString:@"/"]];
	return url;
}

- (NSURL*)URLByDeletingTrailingSlash
{
	PWParameterAssert(self.isFileURL);
	NSURL* url = self;
	if (self.hasTrailingSlash)
        url = [NSURL URLWithString:[self.absoluteString substringToIndex:self.absoluteString.length - 1]];
	return url;
}

@end


NS_ASSUME_NONNULL_END
