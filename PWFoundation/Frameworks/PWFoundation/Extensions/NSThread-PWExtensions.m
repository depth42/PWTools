//
//  NSThread-PWExtensions.m
//  PWFoundation
//
//  Created by Kai Brüning on 29.3.11.
//
//

#import "NSThread-PWExtensions.h"
#import "PWLog.h"
#import <execinfo.h>

@implementation NSThread (PWExtensions)

+ (void) dumCallStackWithVerbosity:(PWCallStackVerbosity)verbosity
{
    NSArray* symbols = [self callStackSymbols];
    
    if (verbosity == PWCallStackExcludeTestSetup) {
        // Remove everything from the end until hitting the first line which does not contain "otest", "SenTestingKit"
        // or "CoreFoundation".
        // Note: the strings all start with the frame index, therefore a prefix test is not possible.

        NSUInteger framesToRemove = 0;
        for (NSString* iSymbol in [symbols reverseObjectEnumerator]) {
            if (   [iSymbol rangeOfString:@"otest"].length == 0
                && [iSymbol rangeOfString:@"SenTestingKit"].length == 0
                && [iSymbol rangeOfString:@"CoreFoundation"].length == 0)
                break;
            ++framesToRemove;
        }
        
        symbols = [symbols subarrayWithRange:NSMakeRange (0, symbols.count - framesToRemove)];
    }
    
    for (NSString* iSymbol in symbols)
        PWLog (@"%@\n", iSymbol);
}

+ (NSArray<NSString*>*)callStackSymbolsFromReturnAddresses:(NSArray<NSNumber*>*)callStack
{
    NSParameterAssert(callStack.count > 0);

    int len = callStack.count;
    void **frames = (void**)malloc(len * sizeof(void*));

    for (int i = 0; i < len; ++i)
        frames[i] = (void *)callStack[i].unsignedIntegerValue;

    char **symbols = backtrace_symbols(frames, len);

    NSMutableArray* symbolStrings = [NSMutableArray arrayWithCapacity:len];
    for (int i = 0; i < len; ++i)
        [symbolStrings addObject:[NSString stringWithFormat:@"%s", symbols[i]]];

    free(frames);
    free(symbols);
    return symbolStrings;
}

@end
