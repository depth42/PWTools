//
//  NSObject-PWExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 22.07.09.
//
//

#import <PWFoundation/PWEnumerable.h>
#import <PWFoundation/PWComparing.h>

@class PWValueType;
@class PWLocality;
@class PWLocalizer;
@protocol PWValueTypeContext;



typedef NS_ENUM(NSUInteger, PWValuePresentationMode)
{
    PWValueIsEditable = 1<<0,   // mutual exclusive with PWValueIsHidden. Note: We intentionally chose bit 0 for editability to be compatible with converted old implementations of presentationMode... which returned a BOOL.
    PWValueIsHidden   = 1<<1,   // mutual exclusive with PWValueIsEditable

    PWValueIsReadOnly = 0,
};
    
typedef void (^PWProtocolEnumerator)(Protocol* iProtocol, BOOL* stop);
typedef void (^PWClassAndProtocolEnumerator)(Class iClass, Protocol* iProtocol, BOOL* stop);
    
typedef enum PWObjectAssociationPolicy {
    PWAssociateObjectUnsafeUnretained,
    PWAssociateObjectStrong,
    PWAssociateObjectStrongAtomic,
    PWAssociateObjectCopy,
    PWAssociateObjectCopyAtomic,
    PWAssociateObjectWeak
} PWObjectAssociationPolicy;
    
@interface NSObject (PWExtensions) < PWEnumerable >

// added convenience to match UXTARGET_OSX
#if UXTARGET_IOS
@property (nonatomic, readonly) NSString* className;
#endif

// A shorter description, suitable to use as part of other object’s descriptions.
// Defaults to -debugTitle if supported and -description else.
@property (nonatomic, readonly, copy) NSString *shortDescription;

// Default implementation calls isEqual:
// Can be overridden by subclasses to implement fuzzy equality checking.
// An implementation is available in NSNumber which does checking via PWEqualDoubles.
- (BOOL)isEqualFuzzy:(id)obj;

// Objects which are not weak referenceable (e.g. NSWindow) can return a PWWeakReferenceProxy from this method.
// NSObject returns self.
@property (nonatomic, readonly, strong)     id  weakReferencableObject;

// Used by PWWeakReferenceProxy to return the referenced obj. All other classes return self.
@property (nonatomic, readonly, strong)     id  weakReferencedObject;

#pragma mark - Object Association

// An Objective-C interface for the C-based associated objects.
// IMPORTANT: the actual key is not the string value, but the string pointer! Therefore it is crucial to use only
// static string constants as keys.
- (void)setAssociatedObject:(id)object forKey:(NSString*)key associationPolicy:(PWObjectAssociationPolicy)associationPolicy;
- (void)setAssociatedObject:(id)object forKey:(NSString*)key copy:(BOOL)copy;   // DEPRECATED forwarder
- (id)associatedObjectForKey:(NSString*)key;
- (void)removeAssociatedObjectForKey:(NSString*)key;    // convenience for setting to nil
- (void)removeAssociatedObjects;

#pragma mark - Changeability

// Looks for a method of the form -(BOOL)mayChange<PropertyKey>Error: If one is found, it is called and its result is returned.
// If no such method is found, YES is returned if the underlying ObjC property is writable. Otherwise NO.
// May be overridden, which is prominently done by PWManagedObject.
- (BOOL)mayChangeValueForKey:(NSString*)key error:(NSError**)outError;

// Follows the specified key path and calls mayChangeValueForKey: for the end objects.
- (BOOL)mayChangeValueForKeyPath:(NSString*)keyPath error:(NSError**)outError;

#pragma mark - Presentation Mode

// Calls mayChangeProperty:error: and if it returns NO the method returns PWValueIsVisible. If it returns YES, 
// it looks for a method of the form -(PWValuePresentationMode)presentationModeFor<key>Description:. If found, it is called and its result is returned.
// If no such method is found, PWValueIsEditable is returned.
// Note: The result of this method should be used to control the editability and visibility of properties to the user.
// Note: The outDescription object should be used to describe why the mode has the given value. Is must not have
// the semantic of an actual error.
// May be overridden, which is prominently done by PWManagedObject.
- (PWValuePresentationMode)presentationModeForKey:(NSString*)key description:(NSError**)outDescription;

// Follows the specified key path and calls presentationModeForKey:error: for the end object.
- (PWValuePresentationMode)presentationModeForKeyPath:(NSString*)keyPath description:(NSError**)outDescription;

#pragma mark - Property User Info

// Starting with the specified class or protocol, these methods recursively looks for plist/strings files
// with a name of the form [className].plist/strings or [protocolName].plist/strings and combines them in a single dictionary.
// All sub-classes and sub-protocols are considered. The result is cached efficiently.
+ (NSDictionary*)userInfoByPropertyNameForClassOrProtocol:(id)classOrProt
                                            defaultBundle:(NSBundle*)defaultBundle;

// Calls +userInfoByPropertyNameForClassOrProtocol:defaultBundle: and returns the entry under the key [name].
+ (NSDictionary*)userInfoForPropertyWithName:(NSString*)name
                           ofClassOrProtocol:(id)classOrProt
                               defaultBundle:(NSBundle*)defaultBundle;

#pragma mark - Property Localization

// Returns a combined localizer from the non-system bundles of the receiver and all its superclasses.
// Cached. Can be overridden by subclasses to return a custom localizer.
+ (PWLocalizer*)defaultLocalizerForLanguage:(NSString*)language;

// Looks up a localized string under the key of the form property.[propertyName] in the defaultLocalizer.
// If it is not found, [propertyName] is looked up. If still not found, value is returned.
+ (NSString*)localizedNameForPropertyWithName:(NSString*)propertyName
                                        value:(NSString*)value
                                     language:(NSString*)language;

// Looks up a localized string under the key of the form property.[propertyName].short in the defaultLocalizer.
+ (NSString*)localizedShortNameForPropertyWithName:(NSString*)propertyName
                                             value:(NSString*)value
                                          language:(NSString*)language;

// Looks up a localized string under the key of the form property.[propertyName].description in the defaultLocalizer.
+ (NSString*)localizedDescriptionForPropertyWithName:(NSString*)propertyName
                                               value:(NSString*)value
                                            language:(NSString*)language;

// Called by the +localizedDescriptionForPropertyWithName:... methods with varying suffixes.
// Can be overridden by subclasses for customizing localization.
+ (NSString*)localizedStringForPropertyWithName:(NSString*)name
                                         suffix:(NSString*)suffix
                                          value:(NSString*)value
                                       language:(NSString*)language;

// Looks up a localized string under the key of the form "entity.[entityName].plural". If none is found,
// it falls back to looking up [entityName].plural. The suffix ".plural" is only added if plural is YES.
+ (NSString*)localizedNameForEntityWithName:(NSString*)entityName
                                     plural:(BOOL)plural
                                      value:(NSString*)value
                                   language:(NSString*)language;


#pragma mark - Value Types

// Looks for a class method of the form +(PWValueType*)<key>ValueType and calls it to provide the type.
+ (PWValueType*)valueTypeForKey:(NSString*)key;

// Looks for an instance method of the form -(PWValueType*)<key>ValueType and calls it to provide the type.
// If none is found, Calls +valueTypeForKey:
// If no value type is returned, the result of -valueTypeForUndefinedKey: is returned.
- (PWValueType*)valueTypeForKey:(NSString*)key;

- (PWValueType*)valueTypeForKeyPath:(NSString*)keyPath;  // only to-one relationships are supported in keyPath

// valueTypeForUndefinedKey: is called if valueTypeForKey: is unsuccessful in finding a type for a key. Standard implementation returns nil. Can be overridden.
- (PWValueType*)valueTypeForUndefinedKey:(NSString*)key;

#pragma mark - Value Formatting

- (NSString*)formattedValueForKey:(NSString*)key
                          context:(id <PWValueTypeContext>)context
                          options:(NSDictionary*)options;

+ (NSString*)formattedValue:(id)value
                     forKey:(NSString*)key
                    context:(id <PWValueTypeContext>)context
                    options:(NSDictionary*)options;

-       (BOOL)value:(id*)outValue
             forKey:(NSString*)key
fromFormattedString:(NSString*)string
            context:(id <PWValueTypeContext>)context
            options:(NSDictionary*)options
              error:(NSError**)outError;

// Treats all keys inside dictionary as property names and tries to set the related value on self by using the value type machanism.
// Returns NO if a property is not found or has no value type.
- (BOOL) applyAttributeValuesFromDictionary:(NSDictionary*)dictionary
                                    context:(id <PWValueTypeContext>)context
                                    options:(NSDictionary*)options
                                      error:(NSError**)outError;

#pragma mark - Key/Value-Coding extensions

// Sends -willChangeValueForKey: and -didChangeValueForKey: together.
- (void)notifyKey:(NSString*)key;

- (BOOL)supportsValueForKeyPath:(NSString*)key;     // Checks whether a call to valueForKeyPath: ends up in NSObject's valueForUndefinedKey:
@property (nonatomic, readonly) BOOL swallowsUndefinedKeyExceptions;             // Used by PWManagedObject for implementing valueForUndefinedKey:

extern NSString* const PWValueForUndefinedKeyMarker;    // Returned by valueForKey: during the check in supportsValueForKeyPath: Needed by PWManagedObject

#pragma mark - Runtime Tools

// Note: resolved the typedef for objc_property_t here to avoid ubiquitous inclusion of a low-level header.
+ (struct objc_property*)propertyWithName:(NSString*)name;

typedef void (^PWPropertyEnumerator)(struct objc_property* iProperty, BOOL* stop);

// Enumerates only the properties defined in this class, not the superclasses.
+ (void)enumeratePropertiesUsingBlock:(PWPropertyEnumerator)block;

// Swizzle instance or class methods.
// 'newSel' must be implemented in the receiving class, 'origSel' somewhere in the super class chain starting at the
// receiver.
// If 'origSel' is not implemented directly in the receiver (that is, the method is inherited by it), a method which
// forwards to super with the original selector must exist in the receiver under the name pwSuper_<origSel>.
+ (void) exchangeInstanceMethod:(SEL)origSel withMethod:(SEL)newSel;
+ (void) exchangeClassMethod:(SEL)origSel withMethod:(SEL)newSel;

// Enumerate the classes in the class hierachy of the receiver which implement 'selector'.
// If 'stopClass' is non-nil, the enumeration stops when it hits this class.
// Note: not really fast, involves copying the method list of every class in the hierachy. Mainly meant for debugging use.
- (void) enumerateImplementationsOfSelector:(SEL)selector
                                  stopClass:(Class)stopClass
                                 usingBlock:(void(^)(Class implementingClass, BOOL* stop))block;

+ (void) enumerateImplementationsOfSelector:(SEL)selector
                                  stopClass:(Class)stopClass
                                 usingBlock:(void(^)(Class implementingClass, BOOL* stop))block;

// Returns wheteher enumeration was stopped
+ (BOOL)enumerateProtocolsRecursively:(BOOL)recurse
                           usingBlock:(PWProtocolEnumerator)block;

+ (void)enumerateSubclassesAndProtocolsUsingBlock:(PWClassAndProtocolEnumerator)block;

// Returns the receiver or a subclass or protocol of the receiver in which a property with the
// given name is defined. A value is returned in either outDefinitionClass or outDefinitionProtocol.
// if both are nil, there is no property with that name.
// The result is cached.
+ (void)definitionClass:(Class*)outDefinitionClass
             orProtocol:(Protocol**)outDefinitionProtocol
    forPropertyWithName:(NSString*)propertyName;

#pragma mark - Tree Enumeration

// Depth first enumeration of a tree rooted at the receiver. The tree is defined by 'childrenAccessor', which is
// mandatory.
// Both visit blocks (if given) are called for all visited items (including the receiver), regardless of the existance
// of children, unless *skipChildren is set to YES. In the latter case 'afterChildren' is not send for this item.
- (void) enumerateTreeDepthFirstWithChildrenAccessor:(id<PWEnumerable>(^)(id parent))childrenAccessor
                                      beforeChildren:(void(^)(id item, BOOL* skipChildren, BOOL* stop))beforeChildren
                                       afterChildren:(void(^)(id item, BOOL* stop))afterChildren;
@end

#ifdef __cplusplus
    extern "C" {
#endif

#pragma mark - Tool Functions
    
NS_INLINE BOOL PWEqualObjects(id objA, id objB)
{
    return objA == objB || [objA isEqual:objB];
}

NS_INLINE BOOL PWEqualObjectsFuzzy(id objA, id objB, BOOL fuzzy)
{
    if(objA == objB)
        return YES;
    return fuzzy ? [objA isEqualFuzzy:objB] : [objA isEqual:objB];
}

NS_INLINE id PWObjectsMaximum(id objA, id objB)
{
    if(!objA)
        return objB;
    if(!objB)
        return objA;
    return [objA compare:objB] == NSOrderedDescending ? objA : objB;
}

NS_INLINE id PWObjectsMinimum(id<PWComparing> objA, id<PWComparing> objB)
{
    if(!objA)
        return objB;
    if(!objB)
        return objA;
    return [objA compare:objB] == NSOrderedAscending ? objA : objB;
}

// Allows nil parameters, considering nil less than anything else.
NSComparisonResult PWCompareObjects(id<PWComparing> objA, id<PWComparing> objB);

#define PW_EPSILON_FOR_EQUALITY 1E-7

// Compare doubles (including NSTimeInterval, PWAbsoluteTime and PWTimeOfDay) for equality with rounding epsilon.
NS_INLINE BOOL PWEqualDoubles (double a, double b)
{
    // Note: the MAX is definitely needed if one of the values is 0.
    // And including = is needed in case both are 0.
    return fabs (a - b) <= MAX (fabs (a), fabs (b)) * PW_EPSILON_FOR_EQUALITY;
}

// Floats have much lower precision.
#define PW_EPSILON_FOR_FLOAT_EQUALITY 1E-5f

NS_INLINE BOOL PWEqualFloats (float a, float b)
{
    return fabsf (a - b) <= MAX (fabsf (a), fabsf (b)) * PW_EPSILON_FOR_FLOAT_EQUALITY;
}

NSString* PWStringFromClass(Class aClass);
    
id PWClassOrProtocolFromString(NSString* string);
    
NSString* PWStringFromClassOrProtocol(id classOrProtocol);
        
FOUNDATION_STATIC_INLINE BOOL PWPointerIsProtocol(id ptr)
{
    return [ptr isKindOfClass:[(id)@protocol(NSObject) class]];
}

#pragma mark - Runtime Tool Functions

// Using respondsToSelector: is about 20 times faster than using conformsToProtocol:
// So for the common case of testing conformance to the NSCopying protocol we
// fall back to using repsondsToSelector on the single method in the protocol.
NS_INLINE BOOL PWConformsToCopying(id obj)
{
    return [obj respondsToSelector:@selector(copyWithZone:)];
}
    
// Returns whether enumeration was stopped
BOOL PWEnumerateSubProtocolsOfProtocol(Protocol* protocol, BOOL recurse, PWProtocolEnumerator block);

// Enumerates only the properties defined in this protocol, not the super protocols.
void PWEnumeratePropertiesOfProtocol(Protocol* protocol, PWPropertyEnumerator block);

// Attach the implementation of the instance resp. class method 'sourceSelector' of 'sourceClass' to
// 'targetClass' under 'targetSelector'.
BOOL PWCopyInstanceMethod (Class sourceClass, SEL sourceSelector, Class targetClass, SEL targetSelector);
    
BOOL PWCopyClassMethod (Class sourceClass, SEL sourceSelector, Class targetClass, SEL targetSelector);
    
BOOL PWCopyMethod (Class sourceClass, SEL sourceSelector, Class targetClass, SEL targetSelector, BOOL isClassMethod);

// obfuscating convenience creating selectors to private methods
NS_INLINE SEL NSSelectorFromComponents(NSArray *components)
{
    return NSSelectorFromString([components componentsJoinedByString:@""]);
}

// obfuscating convenience to private classes
NS_INLINE Class NSClassFromComponents(NSArray *components)
{
    return NSClassFromString([components componentsJoinedByString:@""]);
}

NS_INLINE NSString* NSStringFromKeyPathComponents(NSArray *components)
{
    return [components componentsJoinedByString:@"."];
}

/** PWStringFromKeyPath can be used in methods like keyPathsForValuesAffectingValueForKey:
* to validate during compile time that the given string keypath actually exists on the given target class, e.g.
*
*       return [NSSet setWithObjects: 
*                  PWStringFromKeyPath(MyClass, myClassKeypath),
*                  nil];
*/

#ifndef NDEBUG
    // The block tricks the compiler into compiling the test code without ever executing it.
    // Comma operator is used to return the key path string.
    #define PWStringFromKeyPath(MyClass,keypath) (^{ MyClass* _dummy__; _dummy__.keypath; }, @#keypath)
#else
    #define PWStringFromKeyPath(MyClass,keypath) @#keypath
#endif

#pragma mark - Crash Reporting

// When the app crashes while performing the given block, the attached note is put into the crash report
// in the section "Application Specific Information".
void PWNoteInCrashReportForPerformingBlock(NSString* note, void (^block)(void));
NSString* PWCurrentNoteForCrashReports();

#ifdef __cplusplus
    }
#endif
