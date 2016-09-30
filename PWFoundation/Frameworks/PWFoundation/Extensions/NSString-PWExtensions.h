//
//  NSString-PWExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 19.07.05.
//
//

#import <PWFoundation/PWComparing.h>

@interface NSString (PWExtensions) <PWComparing>

@property (nonatomic, readonly, copy) NSString *quoteQuotes;
@property (nonatomic, readonly, copy) NSString *quoteJavascriptQuotes;
- (NSString*)stringWithSubstitute:(NSString *)subs forCharactersFromSet:(NSCharacterSet *)set;

@property (nonatomic, readonly, copy) NSString *stringByRemovingFirstLine;
@property (nonatomic, readonly, copy) NSString *stringByRemovingLastLine;
- (NSString*)stringByRemovingNumberOfLinesFromBeginning:(NSUInteger)numLines;
// Returns a new string with whitespace characters space and tab trimmed from the
// beginning and the end.
@property (nonatomic, readonly, copy) NSString *stringByRemovingSurroundingWhitespace;
// Returns a new string with multiple consecutive appearances of white characters
// space and tab reduced to just one space character.
@property (nonatomic, readonly, copy) NSString *stringByReducingWhitespaces;
// Returns a new string with whitespaces trimmed from the beginning and the end.
// Whitespaces include space characters, tabs, newlines, carriage returns, and
// any similar characters that do not have a visible representation.
@property (nonatomic, readonly, copy) NSString *stringByTrimmingSpaces;
- (NSString*)stringByURLEscapingWithEncoding:(NSStringEncoding)encoding;
- (NSString*)stringByURLUnescapingWithEncoding:(NSStringEncoding)encoding;

// If the receiver represents a hostname, the following methods add or remove the square brackets
// which are needed around literal ipv6 addresses in URLs
@property (nonatomic, readonly, copy) NSString *URLHostByAddingRequiredBrackets;
@property (nonatomic, readonly, copy) NSString *URLHostByRemovingBrackets;

@property (nonatomic, readonly, copy) NSString *stringByHTMLEscaping;
@property (nonatomic, readonly, copy) NSString *stringWithUppercaseFirstLetter;
@property (nonatomic, readonly, copy) NSString *stringWithLowercaseFirstLetter;
@property (nonatomic, readonly, copy) NSString *stringByCaptializingFirstLetterOfWords;    // Better than built-in capizalizedString method in that it does not lowercase the inner-word letters.
@property (nonatomic, readonly, copy) NSString *stringByTransformingWordsToCamelCase; // " Test the west " --> "testTheWest"

- (NSString*)stringByDeletingSuffix:(NSString*)suffix;
@property (nonatomic, readonly, copy) NSString *stringByRemovingControlCharacters;         // Useful for tidying strings that should be exported to XML which does not allow control characters

- (NSString*)stringByUniquingInTitles:(NSSet*)titles;

+ (NSString*)stringWithInteger:(NSInteger)val base:(NSUInteger)base;
+ (NSString*)stringWithData:(NSData *)data encoding:(NSStringEncoding)encoding;

// Returns a new string by adding string to the beginning and the end.
// string can be nil and in this case a copy of the receiver is returned.
- (NSString*)stringWrappedWithString:(NSString*)string;

- (NSData*)decodeBase64Error:(NSError**)outError;
@property (nonatomic, readonly, copy) NSString *stringByRemovingLineBreaks;
@property (nonatomic, readonly, copy) NSString *stringByRemovingTabsAndLineBreaks;
@property (nonatomic, readonly) BOOL hasMultipleParagraphs;

@property (nonatomic, readonly) BOOL hasTrimmableWhiteSpaceAndNewline;
@property (nonatomic, getter=isWhitespaceAndNewline, readonly) BOOL whitespaceAndNewline;
@property (nonatomic, readonly, copy) NSString *firstKeyPathSegment;

- (NSRange)rangeOfStringWithPrefix:(NSString *)prefix postfix:(NSString *)postfix range:(NSRange)range postfixOptional:(BOOL)postfixOptional;
- (NSUInteger)countOfString:(NSString *)aString options:(NSStringCompareOptions)mask;
- (NSDictionary*)queryDictionaryWithEncoding:(NSStringEncoding)encoding;
- (BOOL)onlyContainsCharactersFromSet:(NSCharacterSet*)set;

// Compares two strings for equality, considering nil and empty string as equal.
+ (BOOL) isStringOrNil:(NSString*)s1 equalToStringOrNil:(NSString*)s2;
+ (NSString*)IANACharSetNameForNSStringEncoding:(NSStringEncoding)encoding;
+ (NSStringEncoding)bestEncodingOfStringInData:(NSData*)data;
- (NSComparisonResult)compare:(NSString*)str locale:(NSLocale*)locale;

@property (nonatomic, readonly, copy) NSString *md5String;

- (BOOL)containsSubstring:(NSString*)substring; // Case sensitive

// Used to make sure no slashes are in potential file names.
// In file names slashes must be replaced with colons in order to be visible in the Finder as slashes.
@property (nonatomic, readonly, copy) NSString *stringByReplacingSlashesWithColons;

#pragma mark common substring

// Foundation NSString already provides a commonPrefixWithString method.
// Unfortunately the mask does not support the NSBackwardsSearch option
// as with the original, possible mask options are NSCaseInsensitiveSearch, NSLiteralSearch
// implementation needs to create reversed string copies and therefore is very expensive
- (NSString *)commonSuffixWithString:(NSString *)aString options:(NSStringCompareOptions)mask;

// same as above with NSStringCompareOptions mask NSLiteralSearch
// implementation does only iterated unichar comparisons and therefore is cheap and fast
- (NSString*)commonSuffixWithString:(NSString*)aString;

// symmetric convenience with NSStringCompareOptions mask NSLiteralSearch
- (NSString*)commonPrefixWithString:(NSString*)aString;

#pragma mark Completion

// Utility method for performing auto-completion in text-fields which allow multiple components in a single field
// separated by a character. For example:
// The resources column can contains semicolon-separated resource titles of the form: My Resource; Another Resource

- (NSString*)completedStringForInsertionIndex:(NSUInteger)insertionIndex
                                    separator:(NSString*)separator                                // single character separator like @";"
                               completedRange:(NSRange*)outCompletedRange                         // optional. Defines which part of the string was completed.
                                    completer:(NSArray* (^)(NSString* partialString))completer;   // Block which returns possible matches for a partial string, or nil if no match is found

#pragma mark Working with Paths

- (NSString*)relativePathToPath:(NSString *)endPath;

// Returns a string with 'backSteps' "..", separated by 'backSteps' - 1 "/".
+ (NSString*) stringWithPathBacksteps:(NSUInteger)backSteps;
+ (NSString*)stringByJoiningString:(NSString*)stringA withString:(NSString*)stringB separator:(NSString*)separator;

#pragma mark Regular Expressions

- (NSString*)substringWithMatch:(NSTextCheckingResult*)match rangeIndex:(NSUInteger)index;

#pragma mark CSS

typedef enum PWCSSNameLocation {
    PWCSSNameLocationRule             = 0,
    PWCSSNameLocationHTMLElementClass = 1,
} PWCSSNameLocation;

// Receiver escaped in a way so that it can be used as a class name in a CSS style rule definition 
// or in the "class" attribute of an HTML element.
// The prefix is added separated by and underscore and must only contain word characters and is needed 
// because CSS/HTML class names and identifiers must not begin with a number and must be longer than two characters.
- (NSString*)stringByEscapingForCSSNameLocation:(PWCSSNameLocation)location prefix:(NSString*)prefix;


// Can be used with a string in the form: <property>:<value>;<property>:<value>;...
// Example: @"max-height:30px;font-size:12px;"
- (NSDictionary*) dictionaryWithCSSProperties;

#pragma mark Quoted printable encoding

// Quoted printable encoding is used in HTTP headers and SMTP messages.
// If the string is encoded as quoted printable, it is split into blocks
// with a maximum length of 76 characters. The first block needs to be shortened
// by the length of the key prefix.
- (NSString*)quotedPrintableStringWithPrefixLength:(NSUInteger)prefixLength
                                          encoding:(NSStringEncoding)encoding;

+ (NSString*)stringFromQuotedPrintableString:(NSString*)quotedPrintableString;

@end

@interface NSString (PWPunycode)

@property (nonatomic, readonly, copy) NSString *punycodeEncodedString;
@property (nonatomic, readonly, copy) NSString *punycodeDecodedString;

// These methods currently expect self to start with a valid scheme.
@property (nonatomic, readonly, copy) NSString *IDNAEncodedString;
@property (nonatomic, readonly, copy) NSString *IDNADecodedString;

@end


// The PWQuote macro converts a macro variable defined in the build settings into an Obj-C string literal
#define PWQuote_(x) @#x
#define PWQuote(x)  PWQuote_(x)

#if defined __cplusplus
extern "C" {
#endif

SEL PWSelectorByExtendingKey(NSString* key, const char* prefix, int prefixLength, const char* suffix, int suffixLength);

#if defined __cplusplus
}   // extern "C"
#endif

// The following macros creates a camel-case style selector from a base key and add a prefix and a suffix respectively.
// The first key character gets uppercased when a prefix is used. 
// The prefix and suffix need to be a compile-time constant C-string.
// For example PWSelectorByExtendingKeyWithPrefixAndSuffix(@"test", "apply", "ReturningError:") results in @selector(applyTestReturningError:)
#define PWSelectorByExtendingKeyWithPrefix(key, prefix)                     PWSelectorByExtendingKey(key, prefix, sizeof(prefix)-1, NULL, 0)
#define PWSelectorByExtendingKeyWithSuffix(key, suffix)                     PWSelectorByExtendingKey(key, NULL, 0, suffix, sizeof(suffix)-1)
#define PWSelectorByExtendingKeyWithPrefixAndSuffix(key, prefix, suffix)    PWSelectorByExtendingKey(key, prefix, sizeof(prefix)-1, suffix, sizeof(suffix)-1)

// the following macro aims for better code readability
#define PWIsEmptyString(a) (a.length == 0)

NS_INLINE NSString* PWEmptyStringForNil(NSString* string)
{
    return string ? string : @"";
}
