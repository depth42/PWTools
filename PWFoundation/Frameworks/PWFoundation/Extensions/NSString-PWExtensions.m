//
//  NSString-PWExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 19.07.05.
//
//

#import "NSString-PWExtensions.h"

#import "NSMutableString-PWExtensions.h"
#import "NSArray-PWExtensions.h"
#import "PWDispatch.h"
#if UXTARGET_OSX
#import "unicode/ucsdet.h"
#endif
#import <CommonCrypto/CommonCrypto.h>

#if UXTARGET_IOS
#import <Security/Security.h>
#endif

@implementation NSString (PWExtensions)

- (NSString*)quoteJavascriptQuotes
{
    NSString* result;
    if([self rangeOfString:@"\""].location == NSNotFound && [self rangeOfString:@"'"].location == NSNotFound)
        result = self;
    else
    {
        NSMutableString* doubleQuotes = [NSMutableString stringWithString:self];
        [doubleQuotes replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:NSLiteralSearch range:NSMakeRange(0, doubleQuotes.length)];
        [doubleQuotes replaceOccurrencesOfString:@"'" withString:@"\\'" options:NSLiteralSearch range:NSMakeRange(0, doubleQuotes.length)];
        result = doubleQuotes;
    }
    return result;
    
}

- (NSString*)quoteQuotes
{
    NSString* result;
    if([self rangeOfString:@"\""].location == NSNotFound && [self rangeOfString:@"\n"].location == NSNotFound && [self rangeOfString:@"\r"].location == NSNotFound)
        result = self;
    else
    {
        NSMutableString *doubleQuotes = [NSMutableString stringWithString:self];
        [doubleQuotes replaceOccurrencesOfString:@"\"" withString:@"\"\"" options:NSLiteralSearch range:NSMakeRange(0, doubleQuotes.length)];
        result = [NSString stringWithFormat:@"\"%@\"", doubleQuotes];
    }
    return result;
}

- (NSString*)stringWithSubstitute:(NSString*)subs
             forCharactersFromSet:(NSCharacterSet*)set
{
    NSRange r = [self rangeOfCharacterFromSet:set];
    if (r.location == NSNotFound) 
        return self;
    NSMutableString* newString = [self mutableCopy];
    do
    {
        [newString replaceCharactersInRange:r withString:subs];
        r = [newString rangeOfCharacterFromSet:set];
    } while (r.location != NSNotFound);
    return newString;
}

- (NSString*)stringByRemovingFirstLine
{
    NSRange range = [self rangeOfString:@"\n" options:0 range:NSMakeRange(0, self.length)];
    if(range.length && range.length < self.length-1)
    {
        range.length = self.length - range.location - 1;
        range.location ++;
        return [self substringWithRange:range];
    }
    return self;    
}

- (NSString*)stringByRemovingNumberOfLinesFromBeginning:(NSUInteger)numLines
{
    NSString *result = self;
    for(NSUInteger i=0; i<numLines; i++)
        result = [result stringByRemovingFirstLine];
    return result;  
}

- (NSString*)stringByRemovingLastLine
{
    NSRange range = [self rangeOfString:@"\n" options:NSBackwardsSearch range:NSMakeRange(0, self.length - 1)];
    if(range.length && range.length < self.length - 1)
    {
        range.length = range.location+1; 
        range.location = 0;
        return [self substringWithRange:range];
    }
    return self;
}

+ (NSString*)directStringWithInteger:(NSInteger)val
                                base:(NSUInteger)base
{
    NSParameterAssert(base > 1 && base <= 16);

    BOOL isNegative = val<0;
    if(isNegative)
        val=-val;
    char buf[32] = {0};
    NSInteger i = 30;
    do
    {
        buf[i--] = "0123456789abcdef"[val % base];
        val /= base;
    } while(val);
    if(isNegative)
        buf[i]='-';
    return (__bridge_transfer NSString*) (CFStringCreateWithCString(NULL, &buf[i+1], kCFStringEncodingASCII));
}

#define STRING_WITH_INTEGER_CACHE_SIZE 20

+ (NSString*)stringWithInteger:(NSInteger)val base:(NSUInteger)base
{
    NSParameterAssert(base > 1 && base <= 16);

    // Use cached instances for the most common small integers.
    if(base == 10 && val>=0 && val<STRING_WITH_INTEGER_CACHE_SIZE)
    {
        static NSArray* cache;
        PWDispatchOnce(^{
            NSMutableArray* intermediateCache = [NSMutableArray arrayWithCapacity:STRING_WITH_INTEGER_CACHE_SIZE];
            for(NSUInteger index=0; index<STRING_WITH_INTEGER_CACHE_SIZE; index++)
                [intermediateCache addObject:[self directStringWithInteger:index base:base]];
            cache = [intermediateCache copy];
        });
        return cache[val];
    }
    else
        return [self directStringWithInteger:val base:base];
}

- (NSString*)stringByRemovingSurroundingWhitespace
{
    NSRange start, end, result;
    static NSCharacterSet* iwsSet;
    PWDispatchOnce(^{
        iwsSet = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
    });

    start = [self rangeOfCharacterFromSet:iwsSet];
    if(start.length == 0)
        return @""; // string is empty or consists of whitespace only

    end = [self rangeOfCharacterFromSet:iwsSet options:NSBackwardsSearch];
    if((start.location == 0) && (end.location == self.length - 1))
        return self;

    result = NSMakeRange(start.location, end.location + end.length - start.location);

    return [self substringWithRange:result];    
}

- (NSData*)decodeBase64Error:(NSError**)outError
{
    // for whatever reason NSDataBase64DecodingIgnoreUnknownCharacters is required on IOS
    return [[NSData alloc] initWithBase64EncodedString:self options:NSDataBase64DecodingIgnoreUnknownCharacters];
}

- (BOOL)hasTrimmableWhiteSpaceAndNewline
{
    if (self.isWhitespaceAndNewline) // no real chars anyway
        return YES;
    
    NSRange frontRange = [self rangeOfCharacterFromSet:self.iwsnSet];
    if (frontRange.length > 0 && frontRange.location > 0) // first real char starts late
        return YES;
    NSRange backRange = [self rangeOfCharacterFromSet:self.iwsnSet options:NSBackwardsSearch];
    if (backRange.length > 0 && NSMaxRange(backRange) < self.length) // last real char ends early
        return YES;

    return NO;
}

- (BOOL)isWhitespaceAndNewline
{
    return ([self rangeOfCharacterFromSet:self.iwsnSet].length == 0);
}

- (NSCharacterSet*)iwsnSet
{
    static NSCharacterSet* iwsnSet;
    PWDispatchOnce(^{
        iwsnSet = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
    });
    return iwsnSet;
}

- (NSString*)stringByReducingWhitespaces
{
    NSCharacterSet *whitespaces = [NSCharacterSet whitespaceCharacterSet];
    NSMutableString *newString = [NSMutableString string];
    BOOL lastCharIsWhitespace = NO;
    NSUInteger length = self.length;
    for(NSUInteger i=0; i<length; i++)
    {
        unichar aChar = [self characterAtIndex:i];
        if([whitespaces characterIsMember:aChar])
        {
            if(!lastCharIsWhitespace)
                [newString appendString:@" "];  
            lastCharIsWhitespace = YES;
        }
        else
        {
            lastCharIsWhitespace = NO;
            [newString appendString:[NSString stringWithCharacters:&aChar length:1]];
        }
    }
    return newString;
}

- (NSString*)stringByTrimmingSpaces
{
    NSMutableString* result = [NSMutableString stringWithString:self];
    CFStringTrimWhitespace((__bridge CFMutableStringRef)result);
    return result;
}

+ (NSString*)stringWithData:(NSData*)data encoding:(NSStringEncoding)encoding
{
    return [[NSString alloc] initWithData:data encoding:encoding];
}

- (NSString*)stringByRemovingLineBreaks
{
    if([self rangeOfString:@"\n"].location != NSNotFound || [self rangeOfString:@"\r"].location != NSNotFound)
    {
        NSMutableString *str = [NSMutableString stringWithString:self];
        [str replaceOccurrencesOfString:@"\n" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, str.length)];
        [str replaceOccurrencesOfString:@"\r" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, str.length)];
        return str;
    }
    return self;
}

- (NSString*)stringByRemovingTabsAndLineBreaks
{
    if([self rangeOfString:@"\n"].location != NSNotFound || [self rangeOfString:@"\r"].location != NSNotFound || [self rangeOfString:@"\t"].location != NSNotFound)
    {
        NSMutableString *str = [NSMutableString stringWithString:self];
        [str replaceOccurrencesOfString:@"\n" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, str.length)];
        [str replaceOccurrencesOfString:@"\r" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, str.length)];
        [str replaceOccurrencesOfString:@"\t" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, str.length)];
       return str;
    }
    return self;
}

- (NSString *)firstKeyPathSegment
{
    NSUInteger dotIndex = [self rangeOfString:@"."].location;
    return dotIndex == NSNotFound ? self : [self substringToIndex:dotIndex];
}

- (NSRange)rangeOfStringWithPrefix:(NSString*)prefix
                           postfix:(NSString*)postfix
                             range:(NSRange)range
                   postfixOptional:(BOOL)postfixOptional
{
    NSRange prefixRange = [self rangeOfString:prefix options:NSLiteralSearch range:range];
    if(prefixRange.location != NSNotFound)
    {
        NSUInteger start = NSMaxRange(prefixRange);
        NSUInteger postfixIndex = [self rangeOfString:postfix options:NSLiteralSearch range:NSMakeRange(start, self.length-start)].location;
        if(postfixIndex == NSNotFound && postfixOptional)
            return NSMakeRange(start, self.length-start);
        else if(postfixIndex != NSNotFound)
            return NSMakeRange(start, postfixIndex-start);
    }
    return NSMakeRange(NSNotFound, 0);
}

- (NSString*)stringByURLEscapingWithEncoding:(NSStringEncoding)encoding
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return (__bridge_transfer NSString*) (CFURLCreateStringByAddingPercentEscapes(NULL, (__bridge CFStringRef)self, NULL, (__bridge CFStringRef)@"+", CFStringConvertNSStringEncodingToEncoding(encoding)));
#pragma clang diagnostic pop
}

- (NSString*)stringByURLUnescapingWithEncoding:(NSStringEncoding)encoding
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    NSMutableString *str = [NSMutableString stringWithString:self];
    [str replaceOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0,str.length)];
    return [str stringByReplacingPercentEscapesUsingEncoding:encoding];
#pragma clang diagnostic pop
}

- (NSString*)stringByHTMLEscaping
{
    NSMutableString *result = [NSMutableString stringWithString:self];
    [result replaceOccurrencesOfString:@"<" withString:@"&lt;" options:NSLiteralSearch range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@">" withString:@"&gt;" options:NSLiteralSearch range:NSMakeRange(0, result.length)];
    return result;
}

- (NSDictionary*)queryDictionaryWithEncoding:(NSStringEncoding)encoding
{
    NSMutableDictionary *result = nil;
    if(self.length)
    {
        result = [NSMutableDictionary dictionary];
        for(NSString *listItem in [self componentsSeparatedByString:@"&"])
        {
            if(listItem.length > 0)
            {
                NSArray *parameters = [listItem componentsSeparatedByString:@"="];
                NSUInteger parametersCount = parameters.count;
                id key = nil;
                id value = nil;
                if(parametersCount == 1)
                {
                    key = parameters[0];
                    key = [key stringByURLUnescapingWithEncoding:encoding];
                }
                else if(parametersCount == 2)
                {
                    key = parameters[0];
                    value = parameters[1];
                    key = [key stringByURLUnescapingWithEncoding:encoding];
                    value = [value stringByURLUnescapingWithEncoding:encoding];
                }
                if(key)
                {
                    NSMutableArray *valueArray = result[key];
                    if(!valueArray)
                    {
                        valueArray = [NSMutableArray array];
                        result[key] = valueArray;
                    }
                    [valueArray addObject:value ? value : @""];
                }
            }
        }
    }
    return result;
}

- (NSString*)stringWithUppercaseFirstLetter
{
    if(self.length == 0)
        return self;
    NSString *firstLetter = [self substringWithRange:NSMakeRange(0,1)];
    return [firstLetter.uppercaseString stringByAppendingString: [self substringFromIndex:1]];  
}

- (NSString*)stringByCaptializingFirstLetterOfWords
{
    NSMutableString* adjustedString = [self mutableCopy];
    NSUInteger length = self.length;
    [self enumerateSubstringsInRange:NSMakeRange(0, length)
                             options:NSStringEnumerationByWords
                          usingBlock:^(NSString *substring, NSRange subRange, NSRange encRange, BOOL *stop) {
                              // There seems to be a bug in the enumeration method. When using NSStringEnumerationByWords and 
                              // no match is found, it reports a ridiculous location (like 18446744073709551615, no it's not NSNotFound)
                              // therefore we have to check whether the reported location actually makes sense
                              if(subRange.location < length) 
                              {
                                  NSRange firstLetterRange = NSMakeRange(subRange.location, 1);
                                  NSString* firstLetter = [self substringWithRange:firstLetterRange];
                                  [adjustedString replaceCharactersInRange:firstLetterRange withString:firstLetter.uppercaseString];
                              }
                          }];
    return adjustedString;
}

// " Test the west " --> "testTheWest"
- (NSString*)stringByTransformingWordsToCamelCase
{
    NSMutableString* adjustedString = [NSMutableString string];
    NSUInteger length = self.length;
    __block BOOL isFirstWord = YES;
    [self enumerateSubstringsInRange:NSMakeRange(0, length)
                             options:NSStringEnumerationByWords
                          usingBlock:^(NSString *substring, NSRange subRange, NSRange encRange, BOOL *stop) {
                              // There seems to be a bug in the enumeration method. When using NSStringEnumerationByWords and
                              // no match is found, it reports a ridiculous location (like 18446744073709551615, no it's not NSNotFound)
                              // therefore we have to check whether the reported location actually makes sense
                              if(subRange.location < length)
                              {
                                  NSString* word = isFirstWord ? [substring stringWithLowercaseFirstLetter] : [substring stringWithUppercaseFirstLetter];
                                  [adjustedString appendString:word];
                              }
                              isFirstWord = NO;
                          }];
    return adjustedString;
}

- (NSString*)stringWithLowercaseFirstLetter
{
    if(self.length==0)
        return self;
    NSString *firstLetter = [self substringWithRange:NSMakeRange(0,1)];
    return [firstLetter.lowercaseString stringByAppendingString: [self substringFromIndex:1]];  
}

+ (BOOL) isStringOrNil:(NSString*)s1 equalToStringOrNil:(NSString*)s2
{
    NSParameterAssert (!s1 || [s1 isKindOfClass:NSString.class]);
    NSParameterAssert (!s2 || [s2 isKindOfClass:NSString.class]);
    
    if (!s1)
        s1 = @"";
    if (!s2)
        s2 = @"";
    return [s1 isEqualToString:s2];
}

- (NSString*)stringByDeletingSuffix:(NSString*)suffix
{
  NSCAssert2([self hasSuffix: suffix], @"'%@' does not have the suffix '%@'", self, suffix);
  return [self substringToIndex: (self.length - suffix.length)];
}

- (NSString*)stringByUniquingInTitles:(NSSet*)titles
{
    NSString* uniqueTitle = self;
    if ([titles containsObject:self]) {
        // Append increasing integer suffix, if a node with this name already exists.
        NSUInteger suffixCount = 2;
        
        // Find and extract an existing suffix from the receiver.
        NSString* bareTitle = self;
        NSRegularExpression* regExp = [NSRegularExpression regularExpressionWithPattern:@"(.+) ([0-9][0-9])" options:0 error:NULL];
        NSTextCheckingResult* match = [regExp firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
        if (match) {
            bareTitle = [self substringWithMatch:match rangeIndex:1];
            suffixCount = [self substringWithMatch:match rangeIndex:2].intValue + 1;
        }
        
        do {
            uniqueTitle = [NSString stringWithFormat:@"%@ %02ld", bareTitle, suffixCount++];
        } while ([titles containsObject:uniqueTitle]);
    }
    return uniqueTitle;
}

- (BOOL)containsSubstring:(NSString*)substring
{
    return [self rangeOfString:substring].location != NSNotFound;
}

- (NSString*)stringWrappedWithString:(NSString*)string
{
    if(!string)
        return [self copy];
    return [NSString stringWithFormat:@"%@%@%@", string, self, string];
}

// Used to make sure no slashes are in potential file names.
// In file names slashes must be replaced with colons in order to be visible in the Finder as slashes.
- (NSString*)stringByReplacingSlashesWithColons
{
    return [self stringByReplacingOccurrencesOfString:@"/" withString:@":"];
}

#pragma mark common substring

- (NSString*)commonPrefixWithString:(NSString*)aString
{
    return [self commonPrefixWithString:aString options:NSLiteralSearch];
}

- (NSString*)commonSuffixWithString:(NSString*)aString
{
    if (self.length == 0) return @"";
    if (aString.length == 0) return @"";
    
    BOOL hasMatch = NO;
    NSUInteger index1 = self.length;
    NSUInteger index2 = aString.length;
    while (MIN(index1, index2) > 0)
    {
        unichar c1 = [self characterAtIndex:index1-1];
        unichar c2 = [aString characterAtIndex:index2-1];

        if (c1 != c2) // NSLiteralSearch
            break;

        hasMatch = YES;
        index1--;
        index2--;
    }
    if (!hasMatch)
        return @"";
    
    return [self substringFromIndex:index1];
}

- (NSString*)commonSuffixWithString:(NSString*)aString options:(NSStringCompareOptions)mask
{
    if(aString == nil) return self;
    return [[self.reverseString commonPrefixWithString:aString.reverseString options:mask] reverseString];
}

- (NSString *)reverseString
{
    NSUInteger len = self.length;
    NSMutableString* rtr = [NSMutableString stringWithCapacity:len];
    
    while (len > 0)
    {
        unichar uch = [self characterAtIndex:--len];
        [rtr appendString:[NSString stringWithCharacters:&uch length:1]];
    }
    return rtr;
}

#pragma mark Working with Paths

- (NSString *)relativePathToPath:(NSString *)endPath
{
    // Note: We use -compare and not isEqualToString to compare path segments
    // to be immune against unicode normalization issues.

    if([endPath compare:self] == NSOrderedSame)
    {
        NSArray *components = self.pathComponents;
        if(components.count > 0)
            return components.lastObject;
        else
            return @"";
    }
    NSMutableArray *startArray = [NSMutableArray arrayWithArray:self.pathComponents];
    NSMutableArray *endArray   = [NSMutableArray arrayWithArray:endPath.pathComponents];
    
    while((startArray.count > 0) && (endArray.count > 0))
    {
        NSString *startSeg = startArray[0];
        NSString *endSeg = endArray[0];
        if([startSeg isEqual:@"/"] || [startSeg compare:endSeg] == NSOrderedSame)
        {
            [startArray removeObjectAtIndex:0];
            [endArray removeObjectAtIndex:0];
        }
        else
            break;
    }
    
    NSString *path = @"";
    for(NSUInteger i=0; i+1<startArray.count; i++) 
        path = [path stringByAppendingPathComponent:@".."];
    
    return [path stringByAppendingPathComponent:[NSString pathWithComponents:endArray]];
}

+ (NSString*) stringWithPathBacksteps:(NSUInteger)backSteps
{
    NSMutableString* path = [NSMutableString string];
    for (NSUInteger i = 0; i < backSteps; ++i) {
        if (i > 0)
            [path appendString:@"/"];
        [path appendString:@".."];
    }
    return [path copy];
}

// Thread-safe version ,because CFStringConvertEncodingToIANACharSetName isn't
+ (NSString*)IANACharSetNameForNSStringEncoding:(NSStringEncoding)encoding
{
    NSString* name;
    switch(encoding)
    {
        case NSUTF8StringEncoding:              name = @"utf-8";        break;
        case NSUTF16StringEncoding:             name = @"utf-16";       break;
        case NSUTF16BigEndianStringEncoding:    name = @"utf-16be";     break;
        case NSUTF16LittleEndianStringEncoding: name = @"utf-16le";     break;
        case NSUTF32StringEncoding:             name = @"utf-32";       break;
        case NSUTF32BigEndianStringEncoding:    name = @"utf-32be";     break;
        case NSUTF32LittleEndianStringEncoding: name = @"utf-32le";     break;
        case NSISOLatin1StringEncoding:         name = @"ISO-8859-1";   break;
        case NSISOLatin2StringEncoding:         name = @"ISO-8859-2";   break;
        case NSASCIIStringEncoding:             name = @"us-ascii";     break;
        case NSJapaneseEUCStringEncoding:       name = @"euc-jp";       break;
        case NSSymbolStringEncoding:            name = @"x-mac-symbol"; break;
        case NSNEXTSTEPStringEncoding:          name = @"x-nextstep";   break;
        case NSShiftJISStringEncoding:          name = @"cp932";        break;
        case NSWindowsCP1251StringEncoding:     name = @"windows-1251"; break;
        case NSWindowsCP1252StringEncoding:     name = @"windows-1252"; break;
        case NSWindowsCP1253StringEncoding:     name = @"windows-1253"; break;
        case NSWindowsCP1254StringEncoding:     name = @"windows-1254"; break;
        case NSWindowsCP1250StringEncoding:     name = @"windows-1250"; break;
        case NSISO2022JPStringEncoding:         name = @"iso-2022-jp";  break;
        case NSMacOSRomanStringEncoding:        name = @"macintosh";    break;
        default:                                name = nil;             break;
    }
    return name;
}

+ (NSString*)stringByJoiningString:(NSString*)stringA withString:(NSString*)stringB separator:(NSString*)separator
{
    NSString* result;
    if(stringA && stringB)
    {
        if(separator)
            result = [[stringA stringByAppendingString:separator] stringByAppendingString:stringB];
        else
            result = [stringA stringByAppendingString:stringB];
    }
    else 
        result = stringA ? stringA : stringB;
    return result;
}

+ (NSStringEncoding)bestEncodingOfStringInData:(NSData*)data
{
#if UXTARGET_IOS
    PWASSERT_NOT_YET_IMPLEMENTED;
    return NSUTF8StringEncoding;
#else
    NSParameterAssert(data);
    NSStringEncoding result = 0;
    UErrorCode errorCode = U_ZERO_ERROR; 
    UCharsetDetector* charsetDetector = ucsdet_open(&errorCode); 
    if(data.length && charsetDetector) 
    {
        ucsdet_setText(charsetDetector, data.bytes, data.length, &errorCode); 
        const UCharsetMatch* match = ucsdet_detect(charsetDetector, &errorCode); 
        if(match)
        {
            const char* encodingName = ucsdet_getName(match, &errorCode); 
            NSString* encodingNameString = @(encodingName); 
            result = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)encodingNameString));
        }
        ucsdet_close(charsetDetector); 
    }
    return result;
#endif
}

- (NSUInteger)countOfString:(NSString *)aString options:(NSStringCompareOptions)mask
{
    NSParameterAssert(aString);
    NSUInteger count = 0;
    NSUInteger len = self.length;
    NSRange range = NSMakeRange(0, len);
    while(range.location < len)
    {
        NSRange match = [self rangeOfString:aString options:mask range:range];
        if(match.location != NSNotFound)
        {
            count++;
            range = NSMakeRange(NSMaxRange(match), len-NSMaxRange(match));
        }
        else 
            break;
    }
    return count;
}

- (BOOL)onlyContainsCharactersFromSet:(NSCharacterSet*)set
{
    NSUInteger length = self.length;
    for(NSUInteger index=0; index<length; index++)
        if(![set characterIsMember:[self characterAtIndex:index]])
            return NO;
    return YES;
}

- (BOOL)hasMultipleParagraphs
{
    __block NSUInteger count = 0;
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length)
                             options:NSStringEnumerationByParagraphs | NSStringEnumerationSubstringNotRequired
                          usingBlock:^(NSString* paragraph, NSRange range, NSRange enclosingRange, BOOL *stop) {
                              count++;
                              if(count>1)
                                  *stop = YES;
                          }];
    return count>1;
}

- (NSComparisonResult)compare:(NSString*)str locale:(NSLocale*)locale
{
    return [self compare:str options:0 range:NSMakeRange(0,self.length) locale:locale];
}

#pragma mark Regular Expression

- (NSString*)substringWithMatch:(NSTextCheckingResult*)match rangeIndex:(NSUInteger)index
{
    if(!match)
        return nil;
    NSRange range = [match rangeAtIndex:index];
    return range.location != NSNotFound ? [self substringWithRange:range] : nil;
}

#pragma mark CSS

- (NSString*)stringByEscapingForCSSNameLocation:(PWCSSNameLocation)location prefix:(NSString*)prefix
{
    NSParameterAssert(location == PWCSSNameLocationRule || location == PWCSSNameLocationHTMLElementClass);
    
    NSMutableString* result = [NSMutableString string];
    
    // To make arbitrary condition names CSS and HTML compatible, we need to 
    // - add a word-character based prefix because CSS names are only allowed to begin with word characters, underscores or minus
    NSUInteger prefixLength = prefix.length;
    if(prefix)
        [result appendString:prefix];
    else
    {
#ifndef NDEBUG
        static NSRegularExpression* startRegex;
        PWDispatchOnce(^{
            startRegex = [NSRegularExpression regularExpressionWithPattern:@"[\\w_].*" 
                                                                   options:NSRegularExpressionCaseInsensitive
                                                                     error:NULL];
        });
        
       NSAssert([startRegex numberOfMatchesInString:@"a" options:NSMatchingAnchored range:NSMakeRange(0, 1)] != 0, @"CSS names have to start with letters or underscores. Provide a prefix if you cannot guarantee it.");    
#endif
   }
    [result appendString:self];
    
    // - replace all spaces with underscores and all underscores with double underscores
    [result replaceOccurrencesOfString:@"_" withString:@"__" options:0 range:NSMakeRange(prefixLength, result.length-prefixLength)];
    [result replaceOccurrencesOfString:@" " withString:@"_"  options:0 range:NSMakeRange(prefixLength, result.length-prefixLength)];
    
    if(location == PWCSSNameLocationRule)
    {
        // For class names in CSS rules we additionally need to
        // escape all non-word and non-underscore characters by a leading backslash.
        static NSRegularExpression* escapeRegex;
        PWDispatchOnce(^{
            escapeRegex = [NSRegularExpression regularExpressionWithPattern:@"([^\\w_])"
                                                                    options:NSRegularExpressionCaseInsensitive
                                                                      error:NULL];
        });
        [escapeRegex replaceMatchesInString:result
                                    options:0 
                                      range:NSMakeRange(prefixLength, result.length-prefixLength)
                               withTemplate:@"\\\\$1"];
    }
    return result;
}

- (NSString*)stringByRemovingControlCharacters
{
	// Ensure that control characters are not present in the string, since they
	// would lead to XML that likely will make servers unhappy.  (Are control
	// characters ever legal in XML?)
	//
	// Why not assert on debug builds for the caller when the string has a control
	// character?  The characters may never be present in the data until the
	// program is deployed to users.  This filtering will make it less likely
	// that bad XML might be generated for users and sent to servers.
	//
	// Since we generate our XML directly from the elements with
	// XMLData, we won't later have a good chance to look for and clean out
	// the control characters.

    static NSCharacterSet* filterChars;

    PWDispatchOnce(^{
        // make a character set of control characters (but not whitespace/newline
        // characters), and keep a static immutable copy to use for filtering
        // strings
        NSCharacterSet* ctrlChars = [NSCharacterSet controlCharacterSet];
        NSCharacterSet* newlineWsChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSCharacterSet* nonNewlineWsChars = [newlineWsChars invertedSet];

        NSMutableCharacterSet* mutableChars = [ctrlChars mutableCopy];
        [mutableChars formIntersectionWithCharacterSet:nonNewlineWsChars];

        [mutableChars addCharactersInRange:NSMakeRange(0x0B, 2)]; // filter vt, ff

        filterChars = [mutableChars copy];
    });
    
	// look for any invalid characters
	NSRange range = [self rangeOfCharacterFromSet:filterChars];
	if (range.location != NSNotFound) {
		
		// copy the string to a mutable, and remove null and non-whitespace
		// control characters
		NSMutableString *mutableStr = [NSMutableString stringWithString:self];
		while (range.location != NSNotFound) {
			
			[mutableStr deleteCharactersInRange:range];
			
			range = [mutableStr rangeOfCharacterFromSet:filterChars];
		}
		
		return mutableStr;
	}

	return self;
}

- (NSString*)md5String
{
    const char* cstr = self.UTF8String;
    unsigned char result[16];
    CC_MD5(cstr, (CC_LONG)strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (NSDictionary*) dictionaryWithCSSProperties
{
    NSMutableDictionary* styleDict = [[NSMutableDictionary alloc] init];
    for(NSString* property in [self componentsSeparatedByString:@";"])
    {
        NSArray* pv = [property componentsSeparatedByString:@":"];
        NSString* key = pv.firstObject;
        if(key.length > 0)
            styleDict[[key stringByRemovingSurroundingWhitespace]] = [pv.lastObject stringByRemovingSurroundingWhitespace];
    }
    return styleDict;
}

#pragma mark Completion

- (NSString*)completedStringForInsertionIndex:(NSUInteger)insertionIndex
                                    separator:(NSString*)separator                                // single character separator like @";"
                               completedRange:(NSRange*)outCompletedRange                         // optional. Defines which part of the string was completed.
                                    completer:(NSArray* (^)(NSString* partialString))completer    // Block which returns possible matches for a partial string, or nil if no match is found
{
    NSParameterAssert(insertionIndex != NSNotFound);
    NSParameterAssert(separator.length == 1);
    NSParameterAssert(outCompletedRange);
    NSParameterAssert(completer);
    
    NSString* result;
    
    NSString* prefix;
    NSString* suffix;
    NSArray* prefixComponents;
    NSArray* suffixComponents;
    
    NSString* component = [self.class componentForInsertionIndex:insertionIndex
                                                        inString:self
                                                       separator:separator
                                                          prefix:&prefix
                                                prefixComponents:&prefixComponents
                                                          suffix:&suffix
                                                suffixComponents:&suffixComponents];
    
    if(component.length > 0)
    {
        NSString* fullyTrimmedComponent = component.stringByTrimmingSpaces;
        NSRange fullyTrimmedComponentRange = [component rangeOfString:fullyTrimmedComponent];
        
        // Note: Fully trimmed component range has NSNotFound location if the whole component was just whitespace.
        NSString* whitespacePrefix = fullyTrimmedComponentRange.location != NSNotFound ? [component substringToIndex:fullyTrimmedComponentRange.location]      : nil;
        NSString* whitespaceSuffix = fullyTrimmedComponentRange.location != NSNotFound ? [component substringFromIndex:NSMaxRange(fullyTrimmedComponentRange)] : nil;
        
        NSString* leftTrimmedComponent = whitespaceSuffix ? [fullyTrimmedComponent stringByAppendingString:whitespaceSuffix] : fullyTrimmedComponent;
        
        // Iterate through all the matches returned from the completer and pick the first one that is not contained in
        // the prefix or suffix components (comparison bases on the entered string, so it could happen that a similar
        // completion suggestion is made - but it will have a different casing).
        NSArray* matches = completer(leftTrimmedComponent);
        for(NSString* match in matches)
        {
            if([prefixComponents containsObject:match] || [suffixComponents containsObject:match])
                continue;

            NSMutableString* resultString = [NSMutableString string];

            [resultString appendString:prefix];
            if(whitespacePrefix)
                [resultString appendString:whitespacePrefix];
            
            *outCompletedRange = NSMakeRange(resultString.length + leftTrimmedComponent.length, match.length - leftTrimmedComponent.length);

            // Adjust the match so that the originally entered characters are still there. Otherwise they would always
            // get replaced and modifying them is uncomfortable (moving in from the right and replacing the first
            // character).
            NSString* modifiedMatch = [match stringByReplacingCharactersInRange:NSMakeRange(0, leftTrimmedComponent.length)
                                                                     withString:leftTrimmedComponent];
            
            [resultString appendString:modifiedMatch];
            [resultString appendString:suffix];
            
            if(![resultString isEqualToString:self])
                result = resultString;
        
            break;
        }
    }
    
    return result;
}

// Utility method for finding the range for an automatic string completion.
// For example: The resources column can contains semicolon-separated resource titles of the form: "My Resource;
// Another Resource"
// The method returns the segment which matches the given insertion index,  and splits the rest of the string into a
// prefix components in front of the segment and suffix components following the segment.

+ (NSString*)componentForInsertionIndex:(NSUInteger)insertionIndex
                               inString:(NSString*)string
                              separator:(NSString*)componentSeparator
                                 prefix:(NSString**)outPrefix
                       prefixComponents:(NSArray**)outPrefixComponents
                                 suffix:(NSString**)outSuffix
                       suffixComponents:(NSArray**)outSuffixComponents
{
    NSParameterAssert(insertionIndex != NSNotFound);
    NSParameterAssert(string);
    NSParameterAssert(componentSeparator.length == 1);
    
    NSUInteger prefixEnd = [string rangeOfString:componentSeparator
                                         options:NSBackwardsSearch | NSLiteralSearch
                                           range:NSMakeRange(0, insertionIndex)].location;
    
    NSUInteger componentStart = prefixEnd != NSNotFound ? prefixEnd + 1 : 0;
    
    NSUInteger suffixStart = [string rangeOfString:componentSeparator
                                           options:NSLiteralSearch
                                             range:NSMakeRange(componentStart, string.length - componentStart)].location;
    
    NSString* prefix = (componentStart > 0)        ? [string substringToIndex:componentStart] : @"";
    NSString* suffix = (suffixStart != NSNotFound) ? [string substringFromIndex:suffixStart]  : @"";
    
    if(outPrefix)
        *outPrefix = prefix;
    if(outSuffix)
        *outSuffix = suffix;
    
    if(outPrefixComponents)
    {
        NSArray* prefixComponents = [prefix componentsSeparatedByString:componentSeparator];
        *outPrefixComponents = [prefixComponents mapWithoutNull:^NSString*(NSString* iComp) {
            NSString* comp = iComp.stringByTrimmingSpaces;
            return comp.length > 0 ? comp : nil;
        }];
    }
    
    if(outSuffixComponents)
    {
        NSArray* suffixComponents = [suffix componentsSeparatedByString:componentSeparator];
        *outSuffixComponents = [suffixComponents mapWithoutNull:^NSString*(NSString* iComp) {
            NSString* comp = iComp.stringByTrimmingSpaces;
            return comp.length > 0 ? comp : nil;
        }];
    }
    
    NSUInteger componentLength = (suffixStart != NSNotFound) ? suffixStart - componentStart : string.length - componentStart;
    return [string substringWithRange:NSMakeRange(componentStart, componentLength)];
}

#pragma mark Quoted printable encoding

// value is encoded quoted-printable, with soft line breaks
// for maximum single lines of 76 chars
// http://www.faqs.org/rfcs/rfc1521.html
- (NSString*)quotedPrintableStringWithPrefixLength:(NSUInteger)prefixLength
                                          encoding:(NSStringEncoding)encoding
{
    NSAssert(self.length > 0, nil);
    
    // If string only uses ASCII characters then it does not need quoted-printable encoding and
    // we can return the string itself.
    if([self canBeConvertedToEncoding:NSASCIIStringEncoding])
        return self;
    
    NSString* encodingName = [NSString IANACharSetNameForNSStringEncoding:encoding];
    
    NSString* softLineStart = [NSString stringWithFormat:@"=?%@?Q?", encodingName];
    NSString* softLineEnd = @"?=";
    // Note: CRLFs are added when the line-breaking methods replaces spaces on full lines with line breaks
    // We keep the algorithm simple by always keeping headroom for the soft line terminator
    NSUInteger maxSoftLineLength = 76 - softLineEnd.length;
    NSParameterAssert(prefixLength < maxSoftLineLength - softLineStart.length);    // we only support short prefixes, like for header keys
    
    NSData* utf8Data = [self dataUsingEncoding:encoding];
    NSUInteger utf8DataLength = utf8Data.length;
    const UInt8* bytes = (const UInt8*)utf8Data.bytes;
    
    NSMutableString* result = [NSMutableString string];
    [result appendString:softLineStart];
    
    NSUInteger remainingSoftLineLength = maxSoftLineLength - softLineStart.length - prefixLength;
    for(NSUInteger dataIndex = 0; dataIndex < utf8DataLength; dataIndex++)
    {
        UInt8 byte = bytes[dataIndex];
        NSUInteger quotedLength = quotedPrintableLengthForByte(byte);
        if(remainingSoftLineLength >= quotedLength)
        {
            appendQuotedPrintableStringForByteToString(byte, result);
            remainingSoftLineLength -= quotedLength;
        }
        else
        {
            [result appendString:softLineEnd];
            [result appendString:@" "];
            [result appendString:softLineStart];
            appendQuotedPrintableStringForByteToString(byte, result);
            remainingSoftLineLength = maxSoftLineLength - softLineStart.length - 1;
        }
    }
    [result appendString:softLineEnd];
    
    return result;
}

NS_INLINE void appendQuotedPrintableStringForByteToString(UInt8 byte, NSMutableString* string)
{
    if(byte == 32)
    {
        UniChar ch = '_';
        CFStringAppendCharacters((__bridge CFMutableStringRef)string, &ch, 1);
    }
    else if(byte == '\t' || byte == '_' || byte == '=' || byte > 127)
    {
        UniChar ch = '=';
        CFStringAppendCharacters((__bridge CFMutableStringRef)string, &ch, 1);
        [string appendIntegerUppercase:byte base:16];
    }
    else
    {
        UniChar ch = byte;
        CFStringAppendCharacters((__bridge CFMutableStringRef)string, &ch, 1);
    }
}

NS_INLINE NSUInteger quotedPrintableLengthForByte(UInt8 byte)
{
    if(byte == '\t' || byte == '_' || byte == '=' || byte > 127)
        return 3;

    return 1;
}

+ (NSString*)stringFromQuotedPrintableString:(NSString*)quotedPrintableString
{
    NSParameterAssert(quotedPrintableString.length > 0);
    
    NSString* encodingName = [NSString stringEncodingNameFromQuotedPrintableString:quotedPrintableString];
    if(!encodingName)
        return quotedPrintableString;
    
    NSStringEncoding encoding = [NSString stringEncodingFromName:encodingName];
    
    NSString* softLineEnd = @"?=";
    NSAssert([quotedPrintableString hasSuffix:softLineEnd], nil);
    
    // Condense quoted printable strings with multiple lines to a single line
    NSMutableString* regularExpression = [NSMutableString stringWithString:@"\\?=\\s*=\\?"];
    [regularExpression appendString:encodingName];
    [regularExpression appendString:@"\\?Q\\?"];
    quotedPrintableString = [quotedPrintableString stringByReplacingOccurrencesOfString:regularExpression
                                                                             withString:@""
                                                                                options:NSRegularExpressionSearch range:NSMakeRange(0, quotedPrintableString.length)];
    
    // Remove the "header" and "footer" of the quoted printable string
    NSUInteger headerLength = encodingName.length + 5;
    NSRange substringRange = NSMakeRange(headerLength, quotedPrintableString.length - headerLength - softLineEnd.length);
    const char* encodedCString = [quotedPrintableString substringWithRange:substringRange].UTF8String;
    
    // Actually decode the quoted printable string
    // Found at http://stackoverflow.com/questions/491678/can-you-translate-php-function-quoted-printable-decode-to-an-nsstring-based-o
    const char *p = encodedCString;
    char *ep, *decodedCString = malloc(strlen(encodedCString) * sizeof(char));
    NSAssert(decodedCString, nil);
    ep = decodedCString;
    
    while(*p)
    {
        switch(*p)
        {
            case '=':
                NSAssert1( *(p + 1) != 0 && *(p + 2) != 0, @"Malformed quoted printable string: %s", encodedCString);
                if( *(p + 1) != '\r' )
                {
                    int i, byte[2];
                    for( i = 0; i < 2; i++ )
                    {
                        byte[i] = *(p + i + 1);
                        if( isdigit(byte[i]) )
                            byte[i] -= 0x30;
                        else
                            byte[i] -= 0x37;
                        NSAssert( byte[i] >= 0 && byte[i] < 16, @"bad encoded character");
                    }
                    *(ep++) = (char) (byte[0] << 4) | byte[1];
                }
                p += 3;
                continue;
            case '_':
                *(ep++) = ' ';
                p++;
                continue;
            default:
                *(ep++) = *(p++);
                continue;
        }
    }
    // null termination of decodedString
    *ep = '\0';
    
    return [[NSString alloc] initWithBytesNoCopy:decodedCString
                                          length:strlen(decodedCString)
                                        encoding:encoding
                                    freeWhenDone:YES];
}

+ (NSString*)stringEncodingNameFromQuotedPrintableString:(NSString*)quotedPrintableString
{
    NSParameterAssert(quotedPrintableString.length > 0);
    
    static NSRegularExpression* regex;
    PWDispatchOnce(^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"^=\\?([^?]+)\\?q\\?"
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:NULL];
    });
    
    NSArray* matches = [regex matchesInString:quotedPrintableString
                                      options:0
                                        range:NSMakeRange(0, quotedPrintableString.length)];
    if(matches.count == 0)
        return nil;
    
    NSRange encodingRange = [matches.firstObject rangeAtIndex:1];
    return [quotedPrintableString substringWithRange:encodingRange];
}

+ (NSStringEncoding)stringEncodingFromName:(NSString*)encodingName
{
    NSParameterAssert(encodingName);
    
    return CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)encodingName));
}

- (NSString*)URLHostByAddingRequiredBrackets
{
    if([self containsString:@":"] && ![self hasPrefix:@"["] && ![self hasSuffix:@"["])
        return [NSString stringWithFormat:@"[%@]", self];
    else
        return self;
}

- (NSString*)URLHostByRemovingBrackets
{
    if([self hasPrefix:@"["] && [self hasSuffix:@"]"])
        return [self substringWithRange:NSMakeRange(1, self.length-2)];
    else
        return self;
}

@end

SEL PWSelectorByExtendingKey(NSString* key, const char* prefix, int prefixLength, const char* suffix, int suffixLength)
{
    NSCParameterAssert(key);
    NSCParameterAssert(prefix || suffix);
    NSCParameterAssert((prefix && prefixLength == strlen(prefix)) || (!prefix && prefixLength == 0));
    NSCParameterAssert((suffix && suffixLength == strlen(suffix)) || (!suffix && suffixLength == 0));

	int keyLength = (int)key.length;
    int bufLength = prefixLength + suffixLength + keyLength + 1;
    char selectorName[bufLength];
    
    char* keyStart = selectorName + prefixLength;
    CFStringGetCString((__bridge CFStringRef)key, keyStart, bufLength - prefixLength, kCFStringEncodingASCII);
    
    if(prefix)
    {
        strncpy(selectorName, prefix, prefixLength);
        *keyStart = toupper(*keyStart);
    }

    if(suffix)
        strcpy(keyStart + keyLength, suffix);
    
    return sel_registerName(selectorName);
}


