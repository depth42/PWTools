//
//  NSMutableString-PWExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 05.12.05.
//
//

#import "NSMutableString-PWExtensions.h"


@implementation NSMutableString (PWExtensions)

- (void)appendInteger:(NSInteger)val base:(NSUInteger)base
{
    char buf[32] = {0};
    NSInteger i = 30;
    do
    {
        buf[i--] = "0123456789abcdef"[val % base];
        val /= base;
    } while(val);
    CFStringAppendCString((__bridge CFMutableStringRef)self, &buf[i+1], kCFStringEncodingASCII);
}

- (void)appendIntegerUppercase:(NSInteger)val base:(NSUInteger)base
{
    char buf[32] = {0};
    NSInteger i = 30;
    do
    {
        buf[i--] = "0123456789ABCDEF"[val % base];
        val /= base;
    } while(val);
    CFStringAppendCString((__bridge CFMutableStringRef)self, &buf[i+1], kCFStringEncodingASCII);
}

- (void)removeInvalidXMLCharacters
{
    // From xml spec valid chars:
    // #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
    // any Unicode character, excluding the surrogate blocks, FFFE, and FFFF.
    // Note: As NSString is UTF-16 based, we do not need to exclude the surrogates in the regular expression.
    NSRegularExpression* expression = [[NSRegularExpression alloc] initWithPattern:@"[^\x09\x0A\x0D\x20-\uD7FF\uE000-\uFFFD]" options:0 error:NULL];
    [expression replaceMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@""];
}

@end
