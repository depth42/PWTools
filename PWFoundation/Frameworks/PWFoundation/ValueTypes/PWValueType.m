//
//  PWValueType.m
//  PWFoundation
//
//  Created by Frank Illenberger on 02.03.10.
//
//

#import "PWValueType.h"
#import "PWDispatch.h"
#import "PWLocality.h"
#import "PWFallbackFormatter.h"
#import "PWErrors.h"
#import "NSObject-PWExtensions.h"
#import "NSBundle-PWExtensions.h"
#import "NSArray-PWExtensions.h"
#import "PWLocalizer.h"
#import "PWAsserts.h"
#import "PWValueGroup.h"

@implementation PWValueType
{
    PWPresetValuesBlock presetValuesBlock_;
}

@synthesize fallbackKeyPath = fallbackKeyPath_;

+ (PWDispatchQueue*)dispatchQueue
{
    static PWDispatchQueue* queue;
    PWDispatchOnce(^{
        queue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWValueType"];
    });
    return queue;
}

static NSString* const SharedInstanceKey = @"net.projectwizards.PWValueType.sharedInstance";

- (instancetype)initWithFallbackKeyPath:(NSString*)fallbackKeyPath 
            presetValuesBlock:(PWPresetValuesBlock)block
{
    if(self = [super init])
    {
        fallbackKeyPath_   = [fallbackKeyPath copy];
        presetValuesBlock_ = [block copy];
    }
    return self;
}

- (instancetype)init
{
    return [self initWithFallbackKeyPath:nil presetValuesBlock:nil];
}

+ (instancetype)valueType
{
    __block PWValueType* type;
    [self.dispatchQueue synchronouslyDispatchBlock:^{
        Class typeClass = self.class;
        type = [typeClass associatedObjectForKey:SharedInstanceKey];
        if(!type)
        {
            type = [[typeClass alloc] initWithFallbackKeyPath:nil presetValuesBlock:nil];
            [typeClass setAssociatedObject:type forKey:SharedInstanceKey copy:NO];
        }
    }];
    return type;
}

- (void)enumeratePresetValuesForContext:(id <PWValueTypeContext>)context
                                 object:(id)object
                        includeNilValue:(BOOL)includeNilValue
                                options:(NSDictionary*)options
                                  block:(void (^)(id value, NSString* name, PWValueCategory category, BOOL* stop))block
{
    NSFormatter* formatter = [self formatterForContext:context options:options object:object keyPath:nil];
    [self configureFormatter:formatter forObject:object keyPath:nil];
    PWValueGroup* valueGroup;
    PWValueTypePresetValuesMode mode = [self presetValuesModeForContext:context object:object options:options values:&valueGroup];
    if(mode != PWValueTypeNoPresetValues)
    {
        BOOL stop = NO;
        if((mode & PWValueTypeNilIsPresetValue) != 0 && includeNilValue)
        {
            // Note: We expect the nil item to be in the basic category.

            // Starting with iOS9/OS X 10.11 SDK, passing nil to stringForObjectValue: creates a compiler warning.
            // We regard this as an error in the SDK and filed a radar on it. In the meantime, we silence the warning.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
            block(nil, [formatter stringForObjectValue:nil], PWValueCategoryBasic, &stop);
#pragma clang diagnostic pop
            if(stop)
                return;
        }

        [valueGroup deepEnumerateValuesWithCategories:PWValueCategoryMaskAll
                                       usingBlock:^(id iValue, PWValueCategory iCategory, BOOL* stop2)
         {
             block(iValue, [formatter stringForObjectValue:iValue], iCategory, stop2);
         }];
    }
}

- (void)enumerateValuesAndGroupsForContext:(id <PWValueTypeContext>)context
                                    object:(id)object
                              omitNilValue:(BOOL)omitNilValue
                                   options:(NSDictionary*)options
                                     block:(void (^)(id value, PWValueGroup* group, NSString* name, PWValueCategory category, BOOL* stop))block
{
    NSFormatter* formatter = [self formatterForContext:context
                                               options:options
                                                object:object
                                               keyPath:nil];
    
    [self configureFormatter:formatter forObject:object keyPath:nil];

    PWValueGroup* valueGroup;
    PWValueTypePresetValuesMode mode = [self presetValuesModeForContext:context
                                                                 object:object
                                                                options:options
                                                                 values:&valueGroup];
    
    if(mode != PWValueTypeNoPresetValues)
    {
        BOOL stop = NO;

        // Call the block for the nil value if needed and not omitted.
        // But only if the nil value is not currently inside the value group:
        if(   !omitNilValue
           && (mode & PWValueTypeNilIsPresetValue) != 0
           && ![valueGroup.deepValues containsObject:NSNull.null])
        {
            // Note: We expect the nil item to be in the basic category.
            // Starting with iOS9/OS X 10.11 SDK, -[NSFormatter stringForObjectValue:] marks the value as nonnull.
            // We regard this as an error in the SDK and filed a radar on it. In the meantime, we silence the warning.
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wnonnull"
            block(nil, nil, [formatter stringForObjectValue:nil], PWValueCategoryBasic, &stop);
        #pragma clang diagnostic pop
            if(stop)
                return;
        }
        
        [valueGroup deepEnumerateWithCategories:PWValueCategoryMaskAll
                                     usingBlock:^(id iValue, PWValueGroup* iGroup, PWValueCategory iCategory, BOOL* stop2)
        {
            BOOL isNilValue = [iValue isEqual:NSNull.null];
            if(isNilValue)
                iValue = nil;
            
            if(!isNilValue || !omitNilValue)
            {
                // See above
            #ifndef __clang_analyzer__
                NSString* name = iGroup ? iGroup.name : [formatter stringForObjectValue:iValue];
                block(iValue, iGroup, name, iCategory, stop2);
            #endif
            }
        }];
    }
}

- (NSFormatter*)formatterForContext:(id <PWValueTypeContext>)context
                            options:(NSDictionary*)options
                             object:(id)object
                            keyPath:(NSString*)keyPath
{
    NSFormatter* formatter;
    id cacheKey;
    if([context respondsToSelector:@selector(cachedValueTypeFormatterForKey:)])
    {
        cacheKey = [self formatterCacheKeyForContext:context
                                             options:options
                                              object:object
                                             keyPath:keyPath];
        if(cacheKey)
        {
            // Note: As fallback key paths are rare, we are ok with performance of wrapping the cacheKey
            // in an array.
            if(fallbackKeyPath_)
                cacheKey = @[fallbackKeyPath_, cacheKey];
            formatter = [context cachedValueTypeFormatterForKey:cacheKey];
        }
    }

    if(!formatter)
    {
        formatter = [self directFormatterForContext:context
                                            options:options
                                             object:object
                                            keyPath:keyPath];
        if(fallbackKeyPath_)    // Wrap formatter to create a formatter that for nil values adds a description of the fallback value in parentheses
            formatter = [[PWFallbackFormatter alloc] initWithFormatter:formatter
                                                               context:context
                                                               options:options
                                                       fallbackKeyPath:fallbackKeyPath_];
        if(cacheKey)
            [context cacheValueTypeFormatter:formatter forKey:cacheKey];
    }
    [self _configureFormatter:formatter forObject:object keyPath:keyPath];
    return formatter;
}

// Overridden by subclasses
- (id <NSCopying>)formatterCacheKeyForContext:(id <PWValueTypeContext>)context
                                      options:(NSDictionary*)options
                                       object:(id)object
                                      keyPath:(NSString*)keyPath
{
    return nil;
}

- (NSFormatter*)formatterForContext:(id <PWValueTypeContext>)context
{
    return [self formatterForContext:context options:nil object:nil keyPath:nil];
}

- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options
                                   object:(id)object
                                  keyPath:(NSString*)keyPath
{
    // default returns nothing, meant for overwriting
    return nil;
}

- (void) _configureFormatter:(NSFormatter*)formatter forObject:(id)object keyPath:(NSString*)keyPath
{
    if(fallbackKeyPath_ && [formatter isKindOfClass:[PWFallbackFormatter class]])
    {
        PWFallbackFormatter* fallbackFormatter = (PWFallbackFormatter*)formatter;
        fallbackFormatter.object = object;
        formatter = fallbackFormatter.formatter;
    }
    [self configureFormatter:formatter forObject:object keyPath:keyPath];
}

- (void) configureFormatter:(NSFormatter*)formatter forObject:(id)object keyPath:(NSString*)keyPath
{
    // default does nothing, meant for overwriting
}

- (NSArray*)formatOptionKeys
{
    return @[PWValueTypeFormatterForImportExportKey];
}

- (PWValueType*)valueTypeForFormatterOptionWithKey:(NSString*)key
{
    NSParameterAssert(key);
    return nil;
}

- (NSArray*) formatterOptionsForDescendingWidths
{
    return nil;
}

- (NSDictionary*)formatterOptions:(NSDictionary*)options appendWithDescendingWidths:(NSDictionary*)other
{
    // subclasses must override. An abstract implementation has no clue on the order of option key values
    // see convenience implementation below
    if (options == nil)
        return other;
    return options;
}

// convenience implementation for single formatKey options (like formatKey : long|short)
+ (NSDictionary*)formatterOptions:(NSDictionary*)options
       appendWithDescendingWidths:(NSDictionary*)other
                   formatsOrdered:(NSArray*)formatsOrderedDescending
                        formatKey:(NSString*)formatKey
{
    PWAssert(formatsOrderedDescending);
    PWAssert(formatKey);
    
    if (options == nil)
        return other;
    
    NSString* format = options[formatKey] ? options[formatKey] : formatsOrderedDescending[0];
    NSString* otherFormat = other[formatKey];
    
    BOOL didChange = NO;
    if (otherFormat && [formatsOrderedDescending indexOfObject:otherFormat] > [formatsOrderedDescending indexOfObject:format])
    {
        format = otherFormat;
        didChange = YES;
    }
    
    if (didChange)
    {
        NSMutableDictionary* result = [NSMutableDictionary dictionary];
        [result addEntriesFromDictionary:options];
        result[formatKey] = format;
        return result;
    }
    
    return options;
}

- (NSDictionary*)preferredFormatterOptions
{
    return nil;
}

- (Class)valueClass
{
    return nil;
}

- (BOOL)isReference
{
    return NO;
}

- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                  values:(PWValueGroup**)outValues
{
    return presetValuesBlock_ ? presetValuesBlock_(context, object, options, outValues) : PWValueTypeNoPresetValues;
}

- (BOOL)value:(id*)outValue
      context:(id <PWValueTypeContext>)targetContext
       object:(id)targetObject
    fromValue:(id)value
     withType:(PWValueType*)type
      context:(id <PWValueTypeContext>)sourceContext
       object:(id)sourceObject
        error:(NSError**)outError
{
    NSParameterAssert(outValue);
    NSParameterAssert(type);
    NSParameterAssert(!value || [value isKindOfClass:type.valueClass]);

    BOOL success = YES;
    if(type == self || [self isKindOfClass:type.class])
        *outValue = value;
    else if(value)
    {
        NSString* errorString;
        NSFormatter* sourceFormatter = [type formatterForContext:sourceContext options:nil object:sourceObject keyPath:nil];
        NSString* stringValue = [sourceFormatter stringForObjectValue:value];
        success = [[self formatterForContext:targetContext options:nil object:targetObject keyPath:nil] getObjectValue:outValue
                                                                                                             forString:stringValue
                                                                                                      errorDescription:&errorString];
        if(!success && outError)
            *outError = [NSError errorWithDomain:PWErrorDomain 
                                            code:PWValueTypeConversionError 
                                        userInfo:errorString ? @{NSLocalizedDescriptionKey: errorString} : nil];
    }
    else
         *outValue = nil;
    return success;
}

// Can be overridden in subclasses
- (NSArray*)presetValuesOptionKeys
{
    return @[];
}

// Can be overridden in subclasses
- (PWValueType*)valueTypeForPresetValuesOptionWithKey:(NSString*)key
{
    return nil;
}

- (NSBundle*)localizationBundle
{
    NSBundle* bundle = [NSBundle bundleForClass:self.class];
    
    return bundle;
}

- (PWLocalizer*)localizerForContext:(id <PWValueTypeContext>)context
{
    return [self localizerForContext:context bundle:self.localizationBundle];
}

- (PWLocalizer*)localizerForContext:(id <PWValueTypeContext>)context bundle:(NSBundle*)bundle
{
    NSString* language = context.locality.language;
    if(!language)
        language = PWLanguageNonLocalized;
    return [bundle localizerForLanguage:language];
}

- (NSString*)localizedStringForKey:(NSString*)key 
                             value:(NSString*)value
                           context:(id <PWValueTypeContext>)context
{
    NSParameterAssert(key);
    
    PWLocalizer* localizer = [self localizerForContext:context];
    
    return [localizer localizedStringForKey:key value:value];
}

- (NSString*)localizedFormatOptionKey:(NSString*)key
                                value:(NSString*)value
                              context:(id <PWValueTypeContext>)context
{
    NSParameterAssert(key);

    return [self localizedStringForKey:[self.formatOptionLocalizationPrefix stringByAppendingString:key]
                                 value:value
                               context:context];
}

- (NSString*)formatOptionLocalizationPrefix
{
    return @"formatOption.";
}

- (NSArray*)typicalValuesInContext:(id <PWValueTypeContext>)context
{
    return nil;
}

- (id)typicalValueInContext:(id <PWValueTypeContext>)context
{
     return [self typicalValuesInContext:context].firstObject;
}

- (id)defaultValueInContext:(id <PWValueTypeContext>)context object:(id)object
{
    // Note: To be able to provide good default values, we use the typical value first and then fall back to the first
    // preset value (if there are any). Most of the preset values start with a value that doesn't make much sense as
    // a default value in the inspector (as it is none or something similar).
    __block id defaultValue = [self typicalValueInContext:context];
    
    if(!defaultValue)
    {
        PWValueGroup* values;
        PWValueTypePresetValuesMode mode = [self presetValuesModeForContext:context object:object options:nil values:&values];
        if(mode != PWValueTypeNoPresetValues)
        {
            [values enumerateWithCategories:PWValueCategoryMaskAll
                                 usingBlock:^(id iValue, PWValueGroup *iGroup, PWValueCategory iCategory, BOOL *stop)
             {
                 defaultValue = iValue;
                 *stop = YES;
             }];
        }
    }

    return defaultValue;
}

+ (BOOL)doPListsSupportValueClass:(Class)valueClass
{
    NSParameterAssert(valueClass);
    return [valueClass isSubclassOfClass:NSString.class] 
    || [valueClass isSubclassOfClass:NSNumber.class]
    || [valueClass isSubclassOfClass:NSDate.class]
    || [valueClass isSubclassOfClass:NSData.class]
    || [valueClass isSubclassOfClass:[NSDictionary class]]
    || [valueClass isSubclassOfClass:[NSArray class]];   
}

- (BOOL)isSupportedByPLists
{
    Class valueClass = self.valueClass;
    return valueClass != Nil && [self.class doPListsSupportValueClass:valueClass];
}

- (BOOL)isNegativeCurrencyValue:(id)value
{
    return NO;
}

@end

NSString* const PWValueTypeFormatterForImportExportKey = @"PWValueTypeFormatterForImportExport";
NSString* const PWValueTypeFormatterForMenuKey         = @"PWValueTypeFormatterForMenu";
