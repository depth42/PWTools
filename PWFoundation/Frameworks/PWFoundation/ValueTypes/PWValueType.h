//
//  PWValueType.h
//  PWFoundation
//
//  Created by Frank Illenberger on 02.03.10.
//
//

#import <PWFoundation/PWValueGroup.h>

@class PWLocality;
@class PWLocalizer;
@class PWValueGroup;
@class PWValueType;

// Note: the protocols declare getters instead of read only properties to avoid trouble with differing lifetime
// qualifiers in adopting classes.

// A value type context provides a high-level context from which value types can derive their basic configuration.
// It is passed into most value type methods.
// The default value types get their locality information from it, but value-type subclasses can require higher-level
// classes as contexts. (MEProject in Merlin for example).
// A value type context needs to be confined to a single dispatch queue, as formatters are mutable non-thread safe objects.
// Contexts can optionally cache created formatters.
@protocol PWValueTypeContext <NSObject>

@property (nonatomic, readonly, strong) PWLocality *locality;

// Most implementers can simply call +[NSObject valueTypeForKey:] but have the chance for redirection.
// Merlin uses this for providing valueTypes for runtime-modelled custom attributes.
- (PWValueType*)valueTypeForKey:(NSString*)key ofClass:(Class)aClass;

@optional
// When a context implements these two cache methods, created formatters are stored and looked up
// via these methods if the value-type class implements -formatterCacheKeyForContext:options:object:keyPath:.
// The are no calls for flushing/removing formatters from the cache, so it is wise to use
// a size-constrained NSCache as the backing store.
- (NSFormatter*)cachedValueTypeFormatterForKey:(id <NSCopying>)cacheKey;
- (void)cacheValueTypeFormatter:(NSFormatter*)formatter forKey:(id <NSCopying>)cacheKey;
@end

// Protocol to acquire a value type context from some other object.
@protocol PWValueTypeContexting <NSObject>
@property (nonatomic, readonly, strong) id<PWValueTypeContext> valueTypeContext;
@end


typedef NS_OPTIONS(int, PWValueTypePresetValuesMode) {
    
    PWValueTypeNoPresetValues                   = 0,
    PWValueTypeAllowsPresetValues               = 1<<0,    // is mutual exclusive with PWValueTypeForcesPresetValues
    PWValueTypeForcesPresetValues               = 1<<1,    // is mutual exclusive with PWValueTypeAllowsPresetValues
    PWValueTypeNilIsPresetValue                 = 1<<2,

    // If set, it means that the preset values are potential members of a NSSet or NSArray or a mask (according to -valueClass)
    // collection in the property. Requires PWValueTypeAllowsPresetValues or PWValueTypeForcesPresetValues.
    PWValueTypePresetValuesArePartOfCollection  = 1<<3
};

typedef PWValueTypePresetValuesMode(^PWPresetValuesBlock)(id <PWValueTypeContext> context, id object, NSDictionary* options, PWValueGroup** outValues);


@interface PWValueType : NSObject 

+ (instancetype)valueType;            // Returns a uniqued default instance

- (instancetype)initWithFallbackKeyPath:(NSString*)fallbackKeyPath            // optional keyPath to a property which provides a fallback for a nil value.
                      presetValuesBlock:(PWPresetValuesBlock)block;

// Calls directFormatterForContext:options: and if a fallbackKeyPath is specified, returns it wrapped inside a fallback formatter.
// The returned instance may be a cached instance, so the resulting formatter needs to be copied if it is to be retained.
// See comments of PWValueTypeContext and -formatterCacheKeyForContext:options:object:keyPath: for more information
// on formatter caching.
// Calls -configureFormatter:forObject:keyPath: every time on the cached formatter instances.
- (NSFormatter*)formatterForContext:(id <PWValueTypeContext>)context
                            options:(NSDictionary*)options              // optional
                             object:(id)object                          // optional
                            keyPath:(NSString*)keyPath;                 // optional

// Should be implemented by subclasses who want to support formatting.
- (NSFormatter*)directFormatterForContext:(id <PWValueTypeContext>)context
                                  options:(NSDictionary*)options        // optional
                                   object:(id)object                    // optional
                                  keyPath:(NSString*)keyPath;           // optional

// Convenience method, forwards to -formatterForContext:context options:nil.
- (NSFormatter*)formatterForContext:(id <PWValueTypeContext>)context;

// Can be overridden by subclasses to support caching of created formatters on the value-type context.
// The returned key has to contain all information from the context, options, object and keyPath which
// should be used to efficiently cache the formatters created by -directFormatterForContext:options:object:keyPath:
// The default implementation returns nil which means no caching.
// It is only called if the value type context also implements -cachedValueTypeFormatterForKey: and -cacheValueTypeFormatter:forKey:.
- (id <NSCopying>)formatterCacheKeyForContext:(id <PWValueTypeContext>)context
                                      options:(NSDictionary*)options    // optional
                                       object:(id)object                // optional
                                      keyPath:(NSString*)keyPath;       // optional

// Called during -formatterForContext:options:object:keyPath:. It is even called every time when
// a cached formatter instance is returned by it.
// The default implementation does nothing.
// Should be implemented by subclasses which want to support formatter configuration which is so efficient
// that it does not need to be cached together with the cached formatter instances.
// Should not be called directly.
- (void) configureFormatter:(NSFormatter*)formatter
                  forObject:(id)object
                    keyPath:(NSString*)keyPath;                         // optional

// The formatter created by formatter for context may offer options. Subclasses may provide their keys by implementing this method.
// This are the keys that formatterForContext:options: can handle in its options parameter.
// By default this returns [PWValueTypeFormatterForImportExportKey].
// For localizing a format option key use -localizedFormatOptionKey:value:context:
@property (nonatomic, readonly, copy)   NSArray* formatOptionKeys;

// Returns nil by default. Can be overridden by subclasses to provide a standard combination of formatter options
// which the type recommends is the best typical represenation for a user.
// Note: PWOutlineColumns use this for example for determining their default widths.
@property (nonatomic, readonly, copy)   NSDictionary* preferredFormatterOptions;

// To provide value type information for the option keys, this method may be implemented in subclasses.
// Subclasses should return super's result for keys they do not handle themselves.
- (PWValueType*)valueTypeForFormatterOptionWithKey:(NSString*)key;

// nil or a series of dictionaries with formatter options which result in stepwise shorter formatted text from the
// start to the end of the array. Used to adjust formatter output to given space.
// Default is nil.
@property (nonatomic, readonly, copy)   NSArray* formatterOptionsForDescendingWidths;

// subclasses must override
// the result should countain the given options with possibly replaced values from the other options if these result in a smaller width
// the default implementation returns the given options ignoring other options or other options if given options are nil
// for consistent behaviour over all types, subclasses may use the convenience implementation below
- (NSDictionary*)formatterOptions:(NSDictionary*)options appendWithDescendingWidths:(NSDictionary*)otherOptions;

// convenience implementation for single formatKey options (like formatKey : long|short)
+ (NSDictionary*)formatterOptions:(NSDictionary*)options
       appendWithDescendingWidths:(NSDictionary*)other
                   formatsOrdered:(NSArray*)formatsOrderedDescending
                        formatKey:(NSString*)formatKey;

// Returns the default values, like for an enumeration type
- (PWValueTypePresetValuesMode)presetValuesModeForContext:(id <PWValueTypeContext>)context
                                                   object:(id)object
                                                  options:(NSDictionary*)options
                                                   values:(PWValueGroup**)outValues;


// The options supported by presetValuesModeForContext:object:options:values:.
// Subclasses may provide their keys by implementing this method.
// By default this returns an empty array.
@property (nonatomic, readonly, copy)   NSArray* presetValuesOptionKeys;

// To provide value type information for the presetValuesOption keys, this method my be implemented in subclasses. 
// Subclasses should return super's result for keys they do not handle themselves.
- (PWValueType*)valueTypeForPresetValuesOptionWithKey:(NSString*)key;

// Enumerates over the default values and their values and their formatted strings (name)
- (void)enumeratePresetValuesForContext:(id <PWValueTypeContext>)context
                                 object:(id)object
                        includeNilValue:(BOOL)includeNilValue   // if nil is a preset value it is used as the first enumeration value
                                options:(NSDictionary*)options
                                  block:(void (^)(id value, NSString* name, PWValueCategory iCategory, BOOL* stop))block;

// For every block invocation, either iValue or iGroup is != nil
// If iValue is nil and iGroup is nil the nil value is meant.
// The values and groups are provided in the order in which they were added.
- (void)enumerateValuesAndGroupsForContext:(id <PWValueTypeContext>)context
                                    object:(id)object
                              omitNilValue:(BOOL)omitNilValue
                                   options:(NSDictionary*)options
                                     block:(void (^)(id value, PWValueGroup* group, NSString* name, PWValueCategory category, BOOL* stop))block;

// Converts values between two values types by using strings and formatters
- (BOOL)value:(id*)outValue
      context:(id <PWValueTypeContext>)targetContext
       object:(id)targetObject
    fromValue:(id)value
     withType:(PWValueType*)type
      context:(id <PWValueTypeContext>)sourceContext
       object:(id)sourceObject
        error:(NSError**)outError;

@property (nonatomic, readonly, strong) Class     valueClass;
@property (nonatomic, readonly, copy)   NSString* fallbackKeyPath;

// Used by -localizerForContext: Defaults to the bundle of the receivers class.
@property (nonatomic, readonly, strong) NSBundle* localizationBundle;

// Used by -localizedStringForKey:value:context: Defaults to the localizer of the localizationBundle. Can be overridden.
- (PWLocalizer*)localizerForContext:(id <PWValueTypeContext>)context;

- (PWLocalizer*)localizerForContext:(id <PWValueTypeContext>)context
                             bundle:(NSBundle*)bundle;

@property (nonatomic, readonly)         BOOL      isSupportedByPLists;   // Value class is string, number, date, array or dictionary. Can be overridden to return NO if array/dictionary contents is not plist compatible.
@property (nonatomic, readonly)         BOOL      isReference;           // Used by PWXMLCoder to decide whether to use "value" or "idref" attribute names. Defaults to NO. Can be overridden.

+ (BOOL)doPListsSupportValueClass:(Class)valueClass;

// The locality of the context provides the language for localization.
// Can be overridden by subclasses
// For localizing formatOption keys use -localizedFormatOptionKey:value:context:
- (NSString*)localizedStringForKey:(NSString*)key 
                             value:(NSString*)value
                           context:(id <PWValueTypeContext>)context;

// Default implementation returns "formatOption.". Can be overridden by subclasses.
@property (nonatomic, readonly, copy)   NSString* formatOptionLocalizationPrefix;

// Calls -localizedStringForKey:value:context: with a key prefixed by -formatOptionLocalizationPrefix
- (NSString*)localizedFormatOptionKey:(NSString*)key
                                value:(NSString*)value
                              context:(id <PWValueTypeContext>)context;

// returns nil by default. May be implemented by subclasses to return values typical
// of this type. These values are used for example to reserve space in a UI layout for values of this type.
- (NSArray*)typicalValuesInContext:(id <PWValueTypeContext>)context;

// Convenience method for returning the first value returned by -typicalValuesInContext:
// This method should not be overridden by subclasses.
- (id)typicalValueInContext:(id <PWValueTypeContext>)context;

// Returns the first preset value if present, the typical value otherwise. Can be overridden for custom behavior.
- (id)defaultValueInContext:(id <PWValueTypeContext>)context object:(id)object;

// Defaults to NO. Can be overridden by subclasses to tell when a value is representing a negative currency amount.
- (BOOL)isNegativeCurrencyValue:(id)value;

@end

@interface PWValueType (OptionalMethods)

// Both methods throw by default.
// Can be implemented by subclasses to support the mapping of values to numbers and back.
// Useful for scalar purposes in plotting.
// The mapping to numbers should be chosen in a way that a plotting algorithm can derive nice tick
// values from them, which means they should preserve the cardinality of the value.
// To achieve this, a reference range may be provided.
// For example: For a work value of "10 days" and a reference range 2 hours - 4 weeks, the
// value type implementation may choose to return the number "2" as for "2 weeks".
// nil values may be turned into NAN
- (double)numberForValue:(id)value
     referenceRangeStart:(id)referenceStartValue
                     end:(id)referenceEndValue
                 context:(id <PWValueTypeContext>)context;

- (id)valueForNumber:(double)number
 referenceRangeStart:(id)referenceStartValue
                 end:(id)referenceEndValue
             context:(id <PWValueTypeContext>)context;

@end

// Key for options dictionary passed to -formatterForContext:options:. Boolean, if YES a formatter suitable for
// import/export is requested.
extern NSString* const PWValueTypeFormatterForImportExportKey;

// Key for options dictionary passed to -formatterForContext:options:. Boolean, if YES a formatter suitable for
// displaying values in a menu is requested.
extern NSString* const PWValueTypeFormatterForMenuKey;

