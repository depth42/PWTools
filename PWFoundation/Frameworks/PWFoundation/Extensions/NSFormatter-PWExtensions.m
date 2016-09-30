//
//  NSFormatter-PWExtensions.m
//  PWFoundation
//
//  Created by Kai Brüning on 1.7.10.
//
//

#import "NSFormatter-PWExtensions.h"
#import "NSError-PWExtensions.h"
#import "PWErrors.h"

@implementation NSFormatter (PWExtensions)

- (void) setReferenceObjectValue:(id)obj
{
    // do nothing, meant for overwriting
}

- (BOOL)getObjectValue:(id*)anObject forString:(NSString*)string error:(NSError**)outError
{
    NSString* errorDescription;
    BOOL success = [self getObjectValue:anObject forString:string errorDescription:outError ? &errorDescription : NULL];
    if(!success && outError)
        *outError = [NSError errorWithDomain:NSCocoaErrorDomain
                                        code:NSFormattingError
                         localizationContext:nil
                                      format:@"%@", errorDescription ? errorDescription : @""];
    return success;
}
@end
