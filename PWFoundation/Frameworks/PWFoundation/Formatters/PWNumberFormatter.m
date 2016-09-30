//
//  PWNumberFormatter.m
//  PWFoundation
//
//  Created by Frank Illenberger on 10.12.09.
//
//

#import "PWNumberFormatter.h"
#import "PWLocality.h"

@implementation PWNumberFormatter

- (BOOL)getObjectValue:(out id *)anObject forString:(NSString *)aString range:(inout NSRange *)rangep error:(out NSError **)error
{
    if(!aString)
    {
        if(anObject)
            *anObject = nil;
        return YES;
    }
    if(self.numberStyle==NSNumberFormatterPercentStyle && self.isLenient)
    {
        aString  = [aString stringByReplacingOccurrencesOfString:@" " withString:@""];
        if(aString.length > 0)
        {
            NSString* percentSymbol = @"%";
            if([aString rangeOfString:percentSymbol].location==NSNotFound)
                aString = [aString stringByAppendingString:percentSymbol];
        }
    }
    return [super getObjectValue:anObject forString:aString range:rangep error:error];
}

- (NSString *)stringForObjectValue:(id)anObject
{
    if(!anObject)
        return nil;
    return [super stringForObjectValue:anObject];
}

@end
