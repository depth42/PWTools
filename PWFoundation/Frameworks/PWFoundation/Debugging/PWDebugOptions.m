//
//  PWDebugOptions.m
//  PWFoundation
//
//  Created by Kai Brüning on 26.1.10.
//
//

#import "PWDebugOptionMacros.h"

// The whole implementation file is made empty if HAS_DEBUG_OPTIONS is 0.

#if HAS_DEBUG_OPTIONS

#import "PWDebugOptions.h"
#import <stdarg.h>
#import "PWDebugOptionGroup.h"

@implementation PWDebugOption

@synthesize title   = title_;
@synthesize toolTip = toolTip_;

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
{
    if ((self = [super init]) != nil) {
        title_   = [title copy];
        toolTip_ = [toolTip copy];
    }
    return self;
}

@end

#pragma mark -

@implementation PWDebugOptionSubGroup

@synthesize subGroup = subGroup_;

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
            subGroup:(Class)subGroupClass
{
    NSParameterAssert (subGroupClass);
    
    if ((self = [super initWithTitle:title toolTip:toolTip]) != nil) {
        subGroup_ = [[subGroupClass alloc] init];
    }
    return self;
}

@end

#pragma mark -

@implementation PWDebugSwitchOption

@synthesize target      = target_;
@synthesize defaultsKey = defaultsKey_;

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
       booleanTarget:(_Atomic (BOOL)*)target defaultValue:(BOOL)value
   defaultsKeySuffix:(NSString*)keySuffix
{
    NSParameterAssert (target);
    
    if ((self = [super initWithTitle:title toolTip:toolTip]) != nil) {
        target_  = target;
        *target_ = value;
        if (keySuffix) {
            defaultsKey_ = [@"DebugOption " stringByAppendingString:keySuffix];
            id defaultValue = [NSUserDefaults.standardUserDefaults objectForKey:defaultsKey_];
            if (defaultValue)
                *target_ = [defaultValue boolValue];
        }
    }
    return self;
}

- (BOOL) currentValue
{
    return *target_;
}

- (void) setCurrentValue:(BOOL)value
{
    *target_ = value;
}

- (void) saveState
{
    if (defaultsKey_) {
        NSUserDefaults* userDefaults = NSUserDefaults.standardUserDefaults;
        [userDefaults setBool:self.currentValue forKey:defaultsKey_];
        [userDefaults synchronize]; // make it persistent even if the app is killed soon after
    }
}

@end

#pragma mark -

@implementation PWDebugEnumOption

@synthesize asSubMenu   = asSubMenu_;
@synthesize target      = target_;
@synthesize defaultsKey = defaultsKey_;
@synthesize values      = values_;
@synthesize titles      = titles_;

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
           asSubMenu:(BOOL)flag
              target:(_Atomic (NSInteger)*)target
        defaultValue:(NSInteger)value
   defaultsKeySuffix:(NSString*)keySuffix
     titlesAndValues:(NSString*)firstTitle, ...
{
    NSParameterAssert (target);
    
    if ((self = [super initWithTitle:title toolTip:toolTip]) != nil) {
        asSubMenu_ = flag;
        target_    = target;
        *target_   = value;
        
        // Collect titles and values.
        NSMutableArray* theTitles = [[NSMutableArray alloc] init];
        NSMutableArray* theValues = [[NSMutableArray alloc] init];
        va_list ap;
        va_start (ap, firstTitle);
        
        NSString* iTitle = firstTitle;
        while (iTitle) {
            [theTitles addObject:iTitle];
            [theValues addObject:@(va_arg (ap, int))];
            
            iTitle = va_arg (ap, NSString*);
        }
        
        va_end (ap);
        
        values_ = [theValues copy];
        titles_ = [theTitles copy];
        
        if (keySuffix) {
            defaultsKey_ = [@"DebugOption " stringByAppendingString:keySuffix];
            id defaultValue = [NSUserDefaults.standardUserDefaults objectForKey:defaultsKey_];
            if (defaultValue)
                *target_ = [defaultValue integerValue];
        }
    }
    return self;
}

- (NSInteger) currentValue
{
    return *target_;
}

- (void) setCurrentValue:(NSInteger)value
{
    *target_ = value;
}

- (void) saveState
{
    if (defaultsKey_) {
        NSUserDefaults* userDefaults = NSUserDefaults.standardUserDefaults;
        [userDefaults setInteger:self.currentValue forKey:defaultsKey_];
        [userDefaults synchronize]; // make it persistent even if the app is killed soon after
    }
}

@end

#pragma mark -

@implementation PWDebugTextOption

@synthesize target      = target_;
@synthesize defaultsKey = defaultsKey_;

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
        stringTarget:(__strong NSString* *)target
   defaultsKeySuffix:(NSString*)keySuffix;
{
    NSParameterAssert (target);
    
    if ((self = [super initWithTitle:title toolTip:toolTip]) != nil) {
        target_  = target;
        *target_ = nil;
        if (keySuffix) {
            defaultsKey_ = [@"DebugOption " stringByAppendingString:keySuffix];
            id defaultValue = [NSUserDefaults.standardUserDefaults objectForKey:defaultsKey_];
            if ([defaultValue isKindOfClass:NSString.class])
                *target_ = defaultValue;
        }
    }
    return self;
}

- (NSString*) currentValue
{
    return *target_;
}

- (void) setCurrentValue:(NSString*)value
{
    *target_ = value;
}

- (void) saveState
{
    if (defaultsKey_) {
        NSUserDefaults* userDefaults = NSUserDefaults.standardUserDefaults;
        [userDefaults setObject:self.currentValue forKey:defaultsKey_];
        [userDefaults synchronize]; // make it persistent even if the app is killed soon after
    }
}

@end

#pragma mark -

@implementation PWDebugActionBlockOption

@synthesize block = block_;

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
         actionBlock:(PWDebugActionBlock)aBlock
{
    NSParameterAssert (aBlock);
    
    if ((self = [super initWithTitle:title toolTip:toolTip]) != nil) {
        block_ = [aBlock copy];
    }
    return self;
}

- (void) execute:(id)sender
{
    block_();
}

@end

#pragma mark -

@implementation PWDebugActionWithNamedTargetOption

@synthesize observableName  = observableName_;
@synthesize keyPath         = keyPath_;
@synthesize selectorName    = selectorName_;
@synthesize options         = options_;

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
      observableName:(NSString*)aName
             keyPath:(NSString*)aKeyPath
        selectorName:(NSString*)aSelectorName
             options:(NSDictionary*)aDict;
{
    NSParameterAssert (aName);
    NSParameterAssert (aSelectorName);
    
    if ((self = [super initWithTitle:title toolTip:toolTip]) != nil) {
        observableName_ = [aName copy];
        keyPath_        = [aKeyPath copy];
        selectorName_   = [aSelectorName copy];
        options_        = [aDict copy];
    }
    return self;
}

@end

#pragma mark -

@implementation PWDebugNamedObservables
@end

#endif /* HAS_DEBUG_OPTIONS */
