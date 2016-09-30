//
//  PWFallbackFormatter.m
//  PWFoundation
//
//  Created by Frank Illenberger on 09.11.10.
//
//

#import "PWFallbackFormatter.h"
#import "PWValueType.h"
#import "PWLocalizer.h"
#import "PWLocality.h"
#import "NSObject-PWExtensions.h"
#import "NSBundle-PWExtensions.h"
#import "PWSDKAvailability.h"

@implementation PWFallbackFormatter

@synthesize formatter       = formatter_;
@synthesize context         = context_;
@synthesize options         = options_;
@synthesize fallbackKeyPath = fallbackKeyPath_;
@synthesize object          = object_;

- (instancetype)init
{
    NSAssert(NO, nil);
    return nil;
}

- (instancetype)initWithFormatter:(NSFormatter*)formatter
                context:(id <PWValueTypeContext>)context
                options:(NSDictionary*)options
        fallbackKeyPath:(NSString*)fallbackKeyPath
{
    NSParameterAssert(formatter);
    NSParameterAssert(fallbackKeyPath);
    
    if(self = [super init])
    {
        formatter_          = formatter;
        options_            = [options copy];
        context_            = context;
        fallbackKeyPath_    = [fallbackKeyPath copy];
    }
    return self;
}

- (BOOL)shouldFallback
{
    // Don't show fallback suffixes for export/import
    return ![options_[PWValueTypeFormatterForImportExportKey] boolValue];
}

- (NSString*)fallbackString
{
    id object = object_;    // weak -> strong
    if(!object)
        return nil;
    PWValueType* fallbackType = [object valueTypeForKeyPath:fallbackKeyPath_];
    if(!fallbackType)
    {
        // If the fallbackKeyPath is not applicable to the given object, we use the default fallback string.
        PWLocalizer* localizer = [[NSBundle bundleForClass:PWFallbackFormatter.class] localizerForLanguage:context_.locality.language];
        return [localizer localizedString:@"fallbackFormatter.default"];
    }
    NSFormatter* fallbackFormatter = [fallbackType formatterForContext:context_ options:options_ object:object keyPath:nil];
    NSAssert(fallbackFormatter != self, nil);
    id fallbackValue = [object valueForKeyPath:fallbackKeyPath_];
    return [fallbackFormatter stringForObjectValue:fallbackValue];
}

- (NSString*)fallbackSuffix
{  
   return self.fallbackString;
}

- (NSString*)stringForObjectValue:(id)value
{
    NSString* string = [formatter_ stringForObjectValue:value];
    if(!value && self.shouldFallback)
    {
        NSString* suffix = self.fallbackSuffix;
        if(suffix)
        {
            if(string.length==0)
                string = suffix;
            else
                string = [string stringByAppendingFormat:@"%@", suffix];
        }
    }
    return string;
}

- (BOOL)getObjectValue:(id*)outValue 
             forString:(NSString*)string
      errorDescription:(NSString**)error
{
    if(self.shouldFallback)
    {
        NSString* fallbackSuffix = self.fallbackSuffix;
        if(fallbackSuffix && [string hasSuffix:fallbackSuffix] && ![string isEqual:fallbackSuffix])   // Remove the fallback suffix if present
        {
            NSUInteger length = string.length;
            NSUInteger endIndex = length - fallbackSuffix.length;
            if(endIndex > 1 && [string characterAtIndex:endIndex] == ' ')
                endIndex--;
            string = [string substringToIndex:endIndex];
        }
    }
    return [formatter_ getObjectValue:outValue forString:string errorDescription:error];
}

@end
