//
//  PWDebugOptionGroup.m
//  PWFoundation
//
//  Created by Kai Brüning on 26.1.10.
//
//

#import "PWDebugOptionMacros.h"

// The whole implementation file is made empty if HAS_DEBUG_OPTIONS is 0.

#if HAS_DEBUG_OPTIONS

#import "PWDebugOptionGroup.h"
#import "PWDebugOptions.h"
#import <objc/runtime.h>


NSString* const PWDebugOptionsEnabledKey = @"DebugOptionsEnabled";

@implementation PWDebugOptionGroup
{
    NSMutableArray* options_;
}

@synthesize options = options_;

- (instancetype) init
{
    if ((self = [super init]) != nil) {
        options_ = [[NSMutableArray alloc] init];

        // Call all methods which begin with 'createOption'.
        Method* methods = class_copyMethodList ([self class], /*outCount =*/NULL);
        if(methods) // is nil if the class does not have any methods on this hierarchy level
        {
            for (Method* iMethod = methods; *iMethod; ++iMethod) {
                // We’re only interested in methods which have no arguments beyond self and cmd.
                if (method_getNumberOfArguments (*iMethod) == 2) {
                    SEL iSel = method_getName (*iMethod);
                    NSString* iSelName = NSStringFromSelector (iSel);
                    if ([iSelName hasPrefix:@"createOption"]) {
                        // Create the option.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [self performSelector:iSel];
#pragma clang diagnostic pop
                    }
                }
            }
            free (methods);
        }
    }
    return self;
}

- (void) addOption:(PWDebugOption*)anOption
{
    NSParameterAssert ([anOption isKindOfClass:[PWDebugOption class]]);
    [options_ addObject:anOption];
}

- (PWDebugOption*) optionWithTitle:(NSString*)title
{
    for (PWDebugOption* iOption in options_)
        if ([iOption.title isEqual:title])
            return iOption;
    return nil;
}

- (void) sortOptionsUsingComparator:(NSComparator)comparator
{
    [options_ sortUsingComparator:comparator];
}

@end

#pragma mark -

@implementation PWRootDebugOptionGroup

+ (PWRootDebugOptionGroup*) createRootGroup
{
    return [[PWRootDebugOptionGroup alloc] init];
}

@end

#endif /* HAS_DEBUG_OPTIONS */
