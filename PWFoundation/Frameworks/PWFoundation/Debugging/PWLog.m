//
//  PWLog.m
//  PWFoundation
//
//  Created by Kai on 27.11.08.
//
//

#import "PWLog.h"
#import "PWDispatch.h"

NS_ASSUME_NONNULL_BEGIN

#if HAS_PWLOG

@interface PWLogger : NSObject
{
@package
    NSUInteger  _inset;
    int         _pendingOpeningBrackets;
    BOOL        _addBracketsAroundInsets;
}

- (void) logText:(NSString*)text;

- (void) push;

- (void) pop;

@property (nonatomic, readonly, copy)   NSString*   insetString;

@property (nonatomic, readwrite)        BOOL        addBracketsAroundInsets;

@end

@interface PWPrintfLogger : PWLogger
@end

@interface PWNSLogLogger : PWLogger
@end

#pragma mark

void pw_log (NSString* format, ...);
void pw_logv (NSString* format, va_list argList);
void enumerateLines (NSString* text, void (^block) (NSString* line, BOOL lastLine));

PWLogger* pw_logger()
{
    PWLogger* logger = NSThread.currentThread.threadDictionary[@"PWLogger"];

    if (!logger) {
        static BOOL sUseNSLog;
        PWDispatchOnce (^{
            sUseNSLog = [NSUserDefaults.standardUserDefaults objectForKey:@"use_NSLog_for_PWLog"] != nil;
        });
        
        logger = [[(sUseNSLog ? PWNSLogLogger.class : PWPrintfLogger.class) alloc] init];
        NSThread.currentThread.threadDictionary[@"PWLogger"] = logger;
    }
    
    return logger;
}

void pw_log (NSString* format, ...)
{
    va_list argList;
    va_start (argList, format);
    
    pw_logv (format, argList);
    
    va_end (argList);
}

void pw_logv (NSString* format, va_list argList)
{
    NSCParameterAssert (format);
    
    // Build the complete string.
    NSString* text = [[NSString alloc] initWithFormat:format arguments:argList];
    [pw_logger() logText:text];
}

void PWLog (NSString* format, ...)
{
    va_list argList;
    va_start (argList, format);
    
    pw_logv (format, argList);
    
    va_end (argList);
}

void PWLogn (NSString* format, ...)
{
    va_list argList;
    va_start (argList, format);
    
    pw_logv (format, argList);
    pw_log (@"\n");
	
    va_end (argList);
}

void PWLogv (NSString* format, va_list args)
{
    pw_logv (format, args);
}

void pw_log_push()
{
    [pw_logger() push];
}

void pw_log_pop()
{
    [pw_logger() pop];
}

void pw_log_setBrackets (BOOL bracketInsets)
{
    pw_logger().addBracketsAroundInsets = bracketInsets;
}

NSString* pw_log_inset()
{
    return pw_logger().insetString;
}

//NSCountedSet* log_contexts()
//{
//    static NSCountedSet* contexts;
//    PWDispatchOnce (^{
//        contexts = [[NSCountedSet alloc] init];
//    });
//    return contexts;
//}
//
//void pw_log_addContext(id context)
//{
//    if(context)
//        [log_contexts() addObject:context];
//}
//
//void pw_log_removeContext(id context)
//{
//    if(context)
//        [log_contexts() removeObject:context];
//}
//
//void PWLogInContext (id context, NSString* format, ...)
//{
//    va_list argList;
//    va_start (argList, format);
//    
//    if(!context || [log_contexts() containsObject:context])
//        pw_logv (format, argList);
//    
//    va_end (argList);
//}
//
//BOOL PWWouldLogInContext (id context)
//{
//    return [log_contexts() containsObject:context];
//}

// Helper for pw_logv.
// 'lastLine' is YES for the last, non-empty line. If the last line is empty (that is, 'text' ends with a line
// separator or is empty), it is skipped and block is never called with 'lastLine' == YES.
void enumerateLines (NSString* text, void (^block) (NSString* line, BOOL lastLine))
{
    NSCParameterAssert (text);
    NSCParameterAssert (block);
    
    // Inserting a string with the %@ format option seems to escape special characters since Mountain Lion (or
    // Xcode 4.5? I don’t know). The following undoes this escaping. Any backslash is removed and the following
    // character (which may be a backslash) taken literally. With the exception of 'n', which is taken as a line
    // separator.
    NSCharacterSet* lineEndChars = [NSCharacterSet characterSetWithCharactersInString:@"\\\n"];
    
    NSScanner* scanner = [NSScanner scannerWithString:text];
    scanner.charactersToBeSkipped = nil;
    
    NSMutableString* line;
    for (;;) {
        NSString* linePart;
        [scanner scanUpToCharactersFromSet:lineEndChars intoString:&linePart];
        BOOL foundLineEnd = YES;
        if (!scanner.isAtEnd) {
            unichar ch = [text characterAtIndex:scanner.scanLocation];
            if (ch == '\\') {
                if (!scanner.isAtEnd) {
                    scanner.scanLocation = scanner.scanLocation + 1;
                    ch = [text characterAtIndex:scanner.scanLocation];
                    if (ch != 'n')
                        foundLineEnd = NO;
                }
            }
            
            if (!foundLineEnd) {
                if (line && linePart.length > 0)
                    [line appendString:linePart];
                else if (linePart.length > 0)
                    line = [NSMutableString stringWithString:linePart];
                else
                    line = [NSMutableString string];
            }
        }
        
        if (foundLineEnd) {
            BOOL lastLine = scanner.isAtEnd;
            
            if (!line) {
                // Empty last line is skipped.
                if (!lastLine || linePart.length > 0)
                    block (linePart, lastLine);
            } else {
                if (linePart.length > 0)
	                [line appendString:linePart];
                // Empty last line is skipped.
                if (!lastLine || line.length > 0)
                    block (line, lastLine);
                line = nil;
            }
            if (lastLine)
                break;
            // Skip the (last) line separating character.
            scanner.scanLocation = scanner.scanLocation + 1;
        }
    }
}

#pragma mark

@implementation PWLogger

- (void) logText:(NSString*)text
{
    [self doesNotRecognizeSelector:_cmd];   // -> sub class
}

- (void) push
{
    ++_inset;
    if (_addBracketsAroundInsets)
        ++_pendingOpeningBrackets;
}

- (void) pop
{
    NSAssert (_inset > 0, @"attempt to pop PWLog inset beyond 0");
    if (_inset > 0)
        --_inset;
}

- (NSString*) insetString
{
    NSString* result = @"";
    NSUInteger count = _inset;
    while (count > 0) {
        result = [result stringByAppendingString:@"   "];
        count--;
    }
    return result;
}

@end

#pragma mark

#define logDest stderr

@implementation PWPrintfLogger
{
    BOOL _startOfLine;
}

- (instancetype) init
{
    self = [super init];
    _startOfLine = YES;
    return self;
}

- (void) logText:(NSString*)text
{
    // Separate into lines.
    enumerateLines (text, ^(NSString* line, BOOL lastLine) {
        if (_startOfLine) {
            int count = 3 * ((int)_inset - _pendingOpeningBrackets);
            while (--count >= 0)
                putc (' ', logDest);
            for (; _pendingOpeningBrackets > 0; --_pendingOpeningBrackets)
                fprintf (logDest, "{  ");
            _startOfLine = NO;
        }
        if (line)
            fprintf (logDest, lastLine ? "%s" : "%s\n", line.UTF8String);
        else if (!lastLine)
            fprintf (logDest, "\n");
        _startOfLine = !lastLine;
    });
}

- (void) pop
{
    [super pop];
    
    if (_pendingOpeningBrackets > 0) {
        --_pendingOpeningBrackets;
    }
    else if (_addBracketsAroundInsets) {
        // Force end of line if necessary.
        if (!_startOfLine)
            [self logText:@"\n"];
        _startOfLine = YES;
        [self logText:@"}\n"];
    }
}

@end

#undef logDest

#pragma mark

@implementation PWNSLogLogger
{
    NSMutableString* _currentLine;
}

- (instancetype) init
{
    self = [super init];
    _currentLine = [NSMutableString string];
    return self;
}

- (void) logText:(NSString*)text
{
    // Separate into lines.
    enumerateLines (text, ^(NSString* line, BOOL lastLine) {
        if (_currentLine.length == 0) {
            int count = 3 * ((int)_inset - _pendingOpeningBrackets);
            while (--count >= 0)
                [_currentLine appendString:@" "];
            for (; _pendingOpeningBrackets > 0; --_pendingOpeningBrackets)
                [_currentLine appendString:@"{  "];
        }
        [_currentLine appendString:line];
        if (!lastLine) {
            NSLog (@"%@", _currentLine);
            [_currentLine deleteCharactersInRange:NSMakeRange(0, _currentLine.length)];
        }
    });
}

- (void) pop
{
    [super pop];
    
    if (_pendingOpeningBrackets > 0) {
        --_pendingOpeningBrackets;
    }
    else if (_addBracketsAroundInsets) {
        // Force end of line if necessary.
        if (_currentLine.length > 0)
            [self logText:@"\n"];
        [self logText:@"}\n"];
    }
}

@end

#endif /* HAS_PWLOG */

NS_ASSUME_NONNULL_END
