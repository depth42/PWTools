//
//  NSObject-PWExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 22.07.09.
//
//

#import "NSObject-PWExtensions.h"

#import "PWDispatch.h"
#import "PWValueTypes.h"
#import "PWPListCoding.h"
#import "PWErrors.h"
#import "PWLocality.h"
#import "PWLocalizer.h"
#import "PWLocalizerCache.h"
#import "PWWeakIndirection.h"
#import "NSArray-PWExtensions.h"
#import "NSError-PWExtensions.h"
#import "NSString-PWExtensions.h"
#import "NSFormatter-PWExtensions.h"
#import "NSBundle-PWExtensions.h"
#import "PWPropertyDefinitionCache.h"
#import <objc/message.h>

#if UXTARGET_OSX
#import <objc/Protocol.h>
#endif

// Make -debugTitle known for implementation of -shortDescription.
@interface NSObject (DebugTitle)
- (NSString*) debugTitle;
@end

@implementation NSObject (PWExtensions)

+ (void) load
{
    [self patchValueForUndefinedKey];
}

#if UXTARGET_IOS
- (NSString*)className
{
    return NSStringFromClass(self.class);
}
#endif

- (NSString*) shortDescription
{
    // Note: need to fall back to -description, because shortDescription is used to generate descriptions of collections
    // and we do not want to remove the standard descriptions of strings and alike.
    return [self respondsToSelector:@selector(debugTitle)] ? [self debugTitle] : self.description;
}

- (BOOL)isEqualFuzzy:(id)obj
{
    return [self isEqual:obj];
}

- (id) weakReferencableObject
{
    return self;
}

- (id) weakReferencedObject
{
    return self;
}

#pragma mark - Associated Objects

- (void)setAssociatedObject:(id)object forKey:(NSString*)key associationPolicy:(PWObjectAssociationPolicy)associationPolicy
{
    // TODO: assert that 'key' is a static string (e.g. by checking the class).
    NSParameterAssert (key);
    
    objc_AssociationPolicy objc_Policy;
    switch (associationPolicy) {
        case PWAssociateObjectUnsafeUnretained:
            objc_Policy = OBJC_ASSOCIATION_ASSIGN; break;
        case PWAssociateObjectStrong:
            objc_Policy = OBJC_ASSOCIATION_RETAIN_NONATOMIC; break;
        case PWAssociateObjectStrongAtomic:
            objc_Policy = OBJC_ASSOCIATION_RETAIN; break;
        case PWAssociateObjectCopy:
            objc_Policy = OBJC_ASSOCIATION_COPY_NONATOMIC; break;
        case PWAssociateObjectCopyAtomic:
            objc_Policy = OBJC_ASSOCIATION_COPY; break;
        case PWAssociateObjectWeak: {
            objc_Policy = OBJC_ASSOCIATION_RETAIN_NONATOMIC;
            object = [[PWWeakIndirection alloc] initWithIndirectedObject:object];
            break;
        }
    }
    objc_setAssociatedObject (self, (__bridge const void*)key, object, objc_Policy);
}

- (void)setAssociatedObject:(id)object forKey:(NSString*)key copy:(BOOL)copy
{
    [self setAssociatedObject:object forKey:key associationPolicy:copy ? PWAssociateObjectCopy : PWAssociateObjectStrong];
}

- (void)removeAssociatedObjectForKey:(NSString*)key
{
    objc_setAssociatedObject (self, (__bridge const void*)key, nil, OBJC_ASSOCIATION_ASSIGN/*does not matter for nil*/);
}

- (id)associatedObjectForKey:(NSString*)key
{
    // TODO: assert that 'key' is a static string (e.g. by checking the class).
    NSParameterAssert (key);
    
    id object = objc_getAssociatedObject(self, (__bridge const void*)key);
    if (object) {
        object = [object pw_indirectedObject];
        // Remove the weak indirection object if indirected object is gone.
        if (!object)
            objc_setAssociatedObject (self, (__bridge const void*)key, nil, OBJC_ASSOCIATION_ASSIGN/*does not matter for nil*/);
    }
    return object;
}

- (void)removeAssociatedObjects
{
    objc_removeAssociatedObjects(self);
}

#pragma mark - PWEnumerable

// By defaults objects enumerate just itselves.

- (NSUInteger) elementCount
{
    return 1;
}

- (NSSet*) asSet
{
    return [NSSet setWithObject:self];
}

- (NSUInteger) countByEnumeratingWithState:(NSFastEnumerationState*)state
                                   objects:(id __unsafe_unretained [])stackbuf
                                     count:(NSUInteger)len
{
    NSParameterAssert (state);
    NSParameterAssert (len > 0);    // passing a zero-length buffer wouldn’t make any sense, would it?
    
    if (state->state != 0)
        return 0;
    
    // We are not tracking mutations, so we'll set state->mutationsPtr to point into one of our extra values,
    // since these values are not otherwise used by the protocol.
    // state->mutationsPtr MUST NOT be NULL.
    state->mutationsPtr = &state->extra[0];
    
    // Set state->itemsPtr to the provided buffer. state->itemsPtr MUST NOT be NULL.
    state->itemsPtr = stackbuf;
    stackbuf[0] = self;
    state->state = 1;
    
    return 1;
}

#pragma mark - Changeability

- (BOOL)mayChangeValueForKey:(NSString*)key error:(NSError**)outError
{
    SEL selector = PWSelectorByExtendingKeyWithPrefixAndSuffix(key, "mayChange", "Error:");
    if([self respondsToSelector:selector])
        return ((BOOL (*)(id, SEL, NSError**))objc_msgSend)(self, selector, outError);
    else
        return YES;
}

- (BOOL)mayChangeValueForKeyPath:(NSString*)keyPath error:(NSError**)outError
{
    BOOL result;
    NSUInteger loc = [keyPath rangeOfString:@"."].location;
    if(loc != NSNotFound)
    {
        NSString* firstKey = [keyPath substringToIndex:loc];
        NSString* remainingPath = [keyPath substringFromIndex:loc+1];
        result = [[self valueForKey:firstKey] mayChangeValueForKeyPath:remainingPath error:outError];
    }
    else
        result = [self mayChangeValueForKey:keyPath error:outError];
    return result;
}

#pragma mark - Presentation Mode

- (PWValuePresentationMode)presentationModeForKey:(NSString*)key description:(NSError**)outDescription
{
    if([self mayChangeValueForKey:key error:outDescription])
    {
        SEL selector = PWSelectorByExtendingKeyWithPrefixAndSuffix(key, "presentationModeFor", "Description:");
        if([self respondsToSelector:selector])
            return ((PWValuePresentationMode (*)(id, SEL, NSError**))objc_msgSend)(self, selector, outDescription);
        else
            return PWValueIsEditable;
    }
    else
        return 0;
}

- (PWValuePresentationMode)presentationModeForKeyPath:(NSString*)keyPath description:(NSError**)outDescription
{
    NSParameterAssert (keyPath);
    
    BOOL result;
    NSUInteger loc = [keyPath rangeOfString:@"."].location;
    if(loc != NSNotFound)
    {
        NSString* firstKey = [keyPath substringToIndex:loc];
        NSString* remainingPath = [keyPath substringFromIndex:loc+1];
        result = [[self valueForKey:firstKey] presentationModeForKeyPath:remainingPath description:outDescription];
    }
    else
        result = [self presentationModeForKey:keyPath description:outDescription];
    return result;
}

#pragma mark - Property User Info

+ (NSDictionary*)userInfoByPropertyNameForClassOrProtocol:(id)classOrProt
                                            defaultBundle:(NSBundle*)defaultBundle
{
    NSParameterAssert(classOrProt);
    
    __block NSDictionary* info;
    static NSMapTable* cache;
    [dispatchQueue() synchronouslyDispatchBlock:^{
        info = [cache objectForKey:classOrProt];
        if(!info)
        {
            if(!cache)
                cache = [NSMapTable strongToStrongObjectsMapTable];
            info = [self _userInfoByPropertyNameForClassOrProtocol:classOrProt defaultBundle:defaultBundle];
            [cache setObject:info forKey:classOrProt];
        }
    }];
    return info;
}

+ (NSDictionary*)userInfoForPropertyWithName:(NSString*)name
                           ofClassOrProtocol:(id)classOrProt
                               defaultBundle:(NSBundle*)defaultBundle
{
    NSParameterAssert(name);
    NSParameterAssert(classOrProt);
    return [self userInfoByPropertyNameForClassOrProtocol:classOrProt defaultBundle:defaultBundle][name];
}

static PWDispatchQueue* dispatchQueue()
{
    static PWDispatchQueue* queue;
    PWDispatchOnce(^{
        queue = [PWDispatchQueue serialDispatchQueueWithLabel:@"net.projectwizards.PWFoundation.NSObject"];
    });
    return queue;
}

+ (NSDictionary*)_userInfoByPropertyNameForClassOrProtocol:(id)classOrProt
                                             defaultBundle:(NSBundle*)defaultBundle
{
    NSParameterAssert(classOrProt);
    

    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    // Recurse first so that duplicate entries for higher-level classes/protocols override the entries of the lower levels

    NSBundle* bundle;
    if(PWPointerIsProtocol(classOrProt))
    {
        PWEnumerateSubProtocolsOfProtocol(classOrProt, NO /* recurse */, ^(Protocol* subprotocol, BOOL* stop) {
            [self mergeUserInfoDictionaries:[self userInfoByPropertyNameForClassOrProtocol:subprotocol defaultBundle:defaultBundle] withDicts:result];
        });
        bundle = defaultBundle;
    }
    else
    {
        bundle = [NSBundle bundleForClass:classOrProt];
        [classOrProt enumerateProtocolsRecursively:NO
                                        usingBlock: ^(Protocol* protocol, BOOL* stop) {
                                            [self mergeUserInfoDictionaries:[self userInfoByPropertyNameForClassOrProtocol:protocol defaultBundle:bundle]  withDicts:result];
                                        }];
        Class superclass = [classOrProt superclass];
        if(superclass)
            [self mergeUserInfoDictionaries:[self userInfoByPropertyNameForClassOrProtocol:superclass defaultBundle:bundle]  withDicts:result];
    }

    NSString* resource = PWStringFromClassOrProtocol(classOrProt);
    NSURL* URL = [bundle URLForResource:resource withExtension:@"plist"];
    if(URL)
    {
        NSError* error;
        NSData* data = [NSData dataWithContentsOfURL:URL options:0 error:&error];
        NSAssert(data, @"Could not read plist with URL '%@': %@", URL, error);
        NSDictionary* plist = [NSPropertyListSerialization propertyListWithData:data
                                                                        options:NSPropertyListImmutable
                                                                         format:NULL
                                                                          error:&error];
        NSAssert(plist, @"Could not read plist with URL '%@': %@", URL, error);
        [self mergeUserInfoDictionaries:plist withDicts:result];
    }
    
    return result;
}

+ (void)mergeUserInfoDictionaries:(NSDictionary*)dictsToMerge
                        withDicts:(NSMutableDictionary*)baseDicts
{
    NSParameterAssert(baseDicts);

    [dictsToMerge enumerateKeysAndObjectsUsingBlock:^(NSString* iPropertyName, NSDictionary* iUserInfo, BOOL *stop) {
        NSDictionary* baseUserInfo = baseDicts[iPropertyName];
        if(baseUserInfo)
        {
            NSMutableDictionary* mutableBaseUserInfo = [baseUserInfo mutableCopy];
            [mutableBaseUserInfo addEntriesFromDictionary:iUserInfo];
            baseDicts[iPropertyName] = mutableBaseUserInfo;
        }
        else
            baseDicts[iPropertyName] = iUserInfo;
    }];
}


#pragma mark - Property Localizing

+ (PWLocalizer*)defaultLocalizerForLanguage:(NSString*)language
{
    NSParameterAssert(language);

    return [PWLocalizerCache.sharedCache localizerForClass:self
                                                  language:language
                                             creationBlock:^PWLocalizer*(Class aClass, NSString* blockLanguage)
            {
                return [self uncachedDefaultLocalizerForLanguage:blockLanguage];
            }];
}

+ (PWLocalizer*)uncachedDefaultLocalizerForLanguage:(NSString*)language
{
    NSParameterAssert(language);

    NSMutableArray* subLocalizers = [NSMutableArray array];
    NSBundle* prevBundle;
    Class iClass = self;
    Class baseClass = NSObject.class;
    while(iClass && iClass != baseClass)
    {
        NSBundle* bundle = [NSBundle bundleForClass:iClass];
        if(bundle.isSystemBundle)
            break;
        if(bundle != prevBundle)
        {
            PWLocalizer* localizer = [bundle localizerForLanguage:language];
            [subLocalizers addObject:localizer];
            prevBundle = bundle;
        }
        iClass = iClass.superclass;
    }

    return subLocalizers.count > 0 ? [PWLocalizer localizerWithSubLocalizers:subLocalizers] : nil;
}

+ (NSString*)localizedNameForPropertyWithName:(NSString*)name
                                        value:(NSString*)value
                                     language:(NSString*)language
{
    NSParameterAssert(name);
    NSParameterAssert(language);

    return [self localizedStringForPropertyWithName:name suffix:nil value:value language:language];
}

+ (NSString*)localizedShortNameForPropertyWithName:(NSString*)name
                                             value:(NSString*)value
                                          language:(NSString*)language
{
    NSParameterAssert(name);
    NSParameterAssert(language);

    return [self localizedStringForPropertyWithName:name suffix:@".short" value:value language:language];
}

+ (NSString*)localizedDescriptionForPropertyWithName:(NSString*)name
                                               value:(NSString*)value 
                                            language:(NSString*)language
{
    NSParameterAssert(name);
    NSParameterAssert(language);

    return [self localizedStringForPropertyWithName:name suffix:@".description" value:value language:language];
}

+ (NSString*)localizedStringForPropertyWithName:(NSString*)name
                                         suffix:(NSString*)suffix
                                          value:(NSString*)value
                                       language:(NSString*)language
{
    NSParameterAssert(name);
    NSParameterAssert(language);
    NSString* result;

    NSString* key = [@"property." stringByAppendingString:name];
    if(suffix)
        key = [key stringByAppendingString:suffix];

    // Determine the name of the Class or the Protocol in which the property was defined and
    // try it first as a dotted prefix.  
    PWLocalizer* prefixLocalizer;
    NSString* contextPrefix = [self definitionContextKeyForPropertyWithName:name language:language localizer:&prefixLocalizer];
    if(contextPrefix)
    {
        NSAssert(prefixLocalizer, nil);
        NSString* prefixedKey = [[contextPrefix stringByAppendingString:@"."] stringByAppendingString:key];
        result = [prefixLocalizer localizedStringForKey:prefixedKey value:nil];
        if(result)
            return result;
    }

    PWLocalizer* localizer = [self defaultLocalizerForLanguage:language];
    if(!contextPrefix)
    {
        contextPrefix = NSStringFromClass(self);
        NSString* prefixedKey = [[contextPrefix stringByAppendingString:@"."] stringByAppendingString:key];
        result = [localizer localizedStringForKey:prefixedKey value:nil];
        if(result)
            return result;
    }

    result = [localizer localizedStringForKey:key value:nil];
    if(!result)
        result = [localizer localizedStringForKey:name value:value];
    return result;
}

+ (NSString*)definitionContextKeyForPropertyWithName:(NSString*)name
                                            language:(NSString*)language
                                           localizer:(PWLocalizer**)outLocalizer
{
    NSParameterAssert(outLocalizer);
    
    Class defClass;
    Protocol* defProtocol;
    [self definitionClass:&defClass orProtocol:&defProtocol forPropertyWithName:name];
    if(defClass)
    {
        *outLocalizer = [defClass defaultLocalizerForLanguage:language];
        return NSStringFromClass(defClass);
    }
    else if(defProtocol)
    {
        *outLocalizer = [self defaultLocalizerForLanguage:language];
        return NSStringFromProtocol(defProtocol);
    }
    else
    {
        *outLocalizer = nil;
        return nil;
    }
}

+ (NSString*)localizedNameForEntityWithName:(NSString*)entityName
                                     plural:(BOOL)plural
                                      value:(NSString*)value
                                   language:(NSString*)language
{
    NSParameterAssert(entityName);
    NSParameterAssert(language);

    if(plural)
        entityName = [entityName stringByAppendingString:@".plural"];
        
    if([language isEqual:PWLanguageNonLocalized])
        return entityName;

    PWLocalizer* localizer = [self defaultLocalizerForLanguage:language];
    NSString* result = [localizer localizedStringForKey:[@"entity." stringByAppendingString:entityName]
                                                  value:nil];
    if(!result)
        result = [localizer localizedStringForKey:entityName
                                            value:value];
    return result;
}

#pragma mark - Value Type

// To be overridden in subclases
- (PWValueType*)valueTypeForUndefinedKey:(NSString*)key
{
    NSParameterAssert(key);
    
    return nil;
}

// To be overridden in subclases
- (PWValueType*)valueTypeForKey:(NSString*)key
{
    NSParameterAssert(key);

    PWValueType* valueType;
    SEL selector = PWSelectorByExtendingKeyWithSuffix(key, "ValueType");
    if([self respondsToSelector:selector])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id type = [self performSelector:selector];
#pragma clang diagnostic pop
        NSAssert(!type || [type isKindOfClass:PWValueType.class], nil);
        valueType = type;
    }
    else
        valueType = [self.class valueTypeForKey:key];
    return valueType ? valueType : [self valueTypeForUndefinedKey:key];
}

+ (PWValueType*)valueTypeForKey:(NSString*)key
{
    NSParameterAssert(key);
    
    PWValueType* valueType;
    SEL selector = PWSelectorByExtendingKeyWithSuffix(key, "ValueType");
    if([self respondsToSelector:selector])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id type = [self performSelector:selector];
#pragma clang diagnostic pop
        NSAssert(!type || [type isKindOfClass:PWValueType.class], nil);
        valueType = type;
    }
    return valueType;
}

- (PWValueType*)valueTypeForKeyPath:(__unsafe_unretained NSString*)keyPath
{
    NSParameterAssert(keyPath);

    PWValueType* result;
    NSUInteger loc = [keyPath rangeOfString:@"."].location;
    if(loc != NSNotFound)
    {
        NSString* firstKey = [keyPath substringToIndex:loc];
        NSString* remainingPath = [keyPath substringFromIndex:loc+1];
        result = [[self valueForKey:firstKey] valueTypeForKeyPath:remainingPath];
    }
    else
        result = [self valueTypeForKey:keyPath];
    return result;
}

#pragma mark - Value Formatting

- (NSString*)formattedValueForKey:(NSString*)key
                          context:(id <PWValueTypeContext>)context
                          options:(NSDictionary*)options
{
    NSParameterAssert(key);
    
    id value = [self valueForKey:key];
    PWValueType* valueType = [self valueTypeForKey:key];
    if(!valueType)
        return [value description];
    NSFormatter* formatter = [valueType formatterForContext:context
                                                    options:options
                                                     object:self
                                                    keyPath:key];
    return [formatter stringForObjectValue:value];
}

+ (NSString*)formattedValue:(id)value
                     forKey:(NSString*)key
                    context:(id <PWValueTypeContext>)context
                    options:(NSDictionary*)options
{
    NSParameterAssert(key);
    
    PWValueType* valueType = [self valueTypeForKey:key];
    if(!valueType)
        return [value description];
    NSFormatter* formatter = [valueType formatterForContext:context
                                                    options:options
                                                     object:self
                                                    keyPath:key];
    return [formatter stringForObjectValue:value];
}

-       (BOOL)value:(id*)outValue
             forKey:(NSString*)key
fromFormattedString:(NSString*)string
            context:(id <PWValueTypeContext>)context
            options:(NSDictionary*)options
              error:(NSError**)outError
{
    NSParameterAssert(key);
    
    PWValueType* valueType = [self valueTypeForKey:key];
    if(!valueType)
        return NO;
    NSFormatter* formatter = [valueType formatterForContext:context
                                                    options:options
                                                     object:self
                                                    keyPath:key];
    return [formatter getObjectValue:outValue forString:string error:outError];
}

- (BOOL) applyAttributeValuesFromDictionary:(NSDictionary*)dictionary
                                    context:(id <PWValueTypeContext>)context
                                    options:(NSDictionary*)options
                                      error:(NSError**)outError
{
    NSParameterAssert(context);
    NSParameterAssert(options);

    for(NSString* attributeName in dictionary)
    {
        id attributeValue = dictionary[attributeName];

        PWValueType* type = [self valueTypeForKey:attributeName];
        if(!type)
        {
            if(outError)
                *outError = [NSError errorWithDomain:PWErrorDomain
                                                code:PWPListCodingParsingError
                                 localizationContext:nil
                                              format:@"%@ unknown  attribute '%@'", NSStringFromClass(self.class), attributeName];
            return NO;
        }
        else
        {
            if([attributeValue isKindOfClass:NSString.class])
            {
                if(![self setStringValue:attributeValue
                                  forKey:attributeName
                                 context:context
                                 options:options
                                   error:outError])
                    return NO;
            }
            else if([type.valueClass conformsToProtocol:@protocol(PWPListCoding)])
            {
                id value = [[type.valueClass alloc] initWithPList:attributeValue
                                                          context:context
                                                            error:outError];
                if(!value)
                    return NO;
                [self setValue:value forKey:attributeName];
            }
            else if([attributeValue isKindOfClass:type.valueClass]) // We simply copy plain attributes.
                [self setValue:attributeValue forKey:attributeName];
            else
            {
                if(outError)
                    *outError = [NSError errorWithDomain:PWErrorDomain
                                                    code:PWPListCodingParsingError
                                     localizationContext:nil
                                                  format:@"Illegal %@ value: '%@/%@'", NSStringFromClass(self.class), attributeName, attributeValue];
                return NO;
            }
        }
    }
    return YES;
}

- (BOOL)setStringValue:(NSString*)string
                forKey:(NSString*)key
               context:(id <PWValueTypeContext>)context
               options:(NSDictionary*)options
                 error:(NSError**)outError
{
    NSParameterAssert(key);
    NSParameterAssert(context);
    NSParameterAssert(options);

    id value;
    if(![self value:&value forKey:key fromFormattedString:string context:context options:options error:outError])
        return NO;

    [self setValue:value forKey:key];

    return YES;
}

#pragma mark - Key/Value Coding Extensions

- (void)notifyKey:(NSString*)key
{
    [self willChangeValueForKey:key];
    [self didChangeValueForKey:key];
}

- (BOOL)supportsValueForKeyPath:(NSString*)keyPath
{
    NSParameterAssert(keyPath);
    
    NSMutableDictionary* threadDict = NSThread.currentThread.threadDictionary;
    
    // We set a marker in the thread local dictionary that lets valueForUndefinedKey: return
    // a marker value instead of throwing an exception. 
    threadDict[PWSwallowsUndefinedKeyExceptionsKey] = @YES;
    BOOL result = ([self valueForKeyPath:keyPath] != PWValueForUndefinedKeyMarker);
    [threadDict removeObjectForKey:PWSwallowsUndefinedKeyExceptionsKey];
    
    return result;
}

- (BOOL)swallowsUndefinedKeyExceptions
{
    return [NSThread.currentThread.threadDictionary[PWSwallowsUndefinedKeyExceptionsKey] boolValue];
}

static NSString* const PWSwallowsUndefinedKeyExceptionsKey = @"PWSwallowsUndefinedKeyExceptions";
NSString* const PWValueForUndefinedKeyMarker = @"PWValueForUndefinedKeyMarker";

// Swizzeled with original implementation from NSObject
- (id)patched_valueForUndefinedKey:(NSString*)key
{
    // Checks for the marker that is set by supportsValueForKeyPath: to return a marker value instead of 
    // throwing an exception.
    if(self.swallowsUndefinedKeyExceptions)
        return PWValueForUndefinedKeyMarker; // The marker is picked up by supportsValueForKeyPath:
    else
    {
        static NSString* const isKindOfClassPrefix  = @"isKindOfClass";
        if([key hasPrefix:isKindOfClassPrefix])
            return @([self isKindOfClass:NSClassFromString([key substringFromIndex:isKindOfClassPrefix.length])]);
        else
            return [self patched_valueForUndefinedKey:key];    // this is not a recursion because of exchanged implementations
    }
}

+ (void) patchValueForUndefinedKey
{
    Method original = class_getClassMethod (self, @selector(valueForUndefinedKey:));
    NSAssert (original, nil);
    Method patched  = class_getClassMethod (self, @selector(patched_valueForUndefinedKey:));
    NSAssert (patched, nil);
    method_exchangeImplementations (original, patched);
}

#pragma mark - Runtime tools

+ (void)definitionClass:(Class*)outDefinitionClass
             orProtocol:(Protocol**)outDefinitionProtocol
    forPropertyWithName:(NSString*)propertyName
{
    NSParameterAssert(outDefinitionClass);
    NSParameterAssert(outDefinitionProtocol);
    NSParameterAssert(propertyName);

    [PWPropertyDefinitionCache.sharedCache definitionClass:outDefinitionClass
                                                orProtocol:outDefinitionProtocol
                                       forPropertyWithName:propertyName
                                                   inClass:self];
}

+ (objc_property_t)propertyWithName:(NSString*)name
{
    return class_getProperty(self, name.UTF8String);
}

+ (void) exchangeInstanceMethod:(SEL)origSel withMethod:(SEL)newSel
{
    NSParameterAssert (origSel);
    NSParameterAssert (newSel);
    
    Class superclass = self.superclass;
    
    Method newMethod = class_getInstanceMethod (self, newSel);
    NSAssert (class_getInstanceMethod (superclass, newSel) != newMethod, @"replacement method must be implemented in this class");

    Method origMethod = class_getInstanceMethod (self, origSel);
    NSAssert (origMethod, @"original method must be implemented somewhere in hierachy");

    if (class_getInstanceMethod (superclass, origSel) == origMethod) {
        // The original method is implemented in some super class of this class. In this case we need to add a method
        // to this class which simply forwards to super to have a proper target for swizzeling (without doing this we
        // would exchange the implementation in a base class, which is not good).
        // We use a naming convention to address the forwarding method.
        SEL forwardSel = NSSelectorFromString([@"pwSuper_" stringByAppendingString:NSStringFromSelector(origSel)]);
        Method forwardMethod = class_getInstanceMethod (self, forwardSel);
        NSAssert (forwardMethod, @"did not find a method to forward to super");
        NSAssert (class_getInstanceMethod (superclass, forwardSel) != forwardMethod, @"forward method must be implemented in this class");

        // Add our forward method under the original selector for swizzeling with newSel below.
        BOOL success = class_addMethod (self,
                                        origSel,
                                        method_getImplementation (forwardMethod),
                                        method_getTypeEncoding (forwardMethod));
        NSAssert (success, nil);
        origMethod = class_getInstanceMethod (self, origSel);
        // Now the original selector is implemented in this class.
        NSAssert (class_getInstanceMethod (superclass, origSel) != origMethod, @"hä?");
    }
    
    NSAssert (origMethod != newMethod, nil);
    method_exchangeImplementations (origMethod, newMethod);
}

// Same as above for class methods.
+ (void) exchangeClassMethod:(SEL)origSel withMethod:(SEL)newSel
{
    NSParameterAssert (origSel);
    NSParameterAssert (newSel);
    
    Class superclass = self.superclass;
    
    Method newMethod = class_getClassMethod (self, newSel);
    NSAssert (class_getClassMethod (superclass, newSel) != newMethod, @"replacement method must be implemented in this class");
    
    Method origMethod = class_getClassMethod (self, origSel);
    NSAssert (origMethod, @"original method must be implemented somewhere in hierachy");
    
    if (class_getClassMethod (superclass, origSel) == origMethod) {
        SEL forwardSel = NSSelectorFromString([@"pwSuper_" stringByAppendingString:NSStringFromSelector(origSel)]);
        Method forwardMethod = class_getClassMethod (self, forwardSel);
        NSAssert (forwardMethod, @"did not find a method to forward to super");
        NSAssert (class_getClassMethod (superclass, forwardSel) != forwardMethod, @"forward method must be implemented in this class");
        
        Class selfMetaClass = objc_getMetaClass (class_getName (self));
        NSAssert (selfMetaClass, nil);   // should never fail if 'self' is a valid class
        BOOL success = class_addMethod (selfMetaClass,
                                        origSel,
                                        method_getImplementation (forwardMethod),
                                        method_getTypeEncoding (forwardMethod));
        NSAssert (success, nil);
        origMethod = class_getClassMethod (self, origSel);
        NSAssert (class_getClassMethod (superclass, origSel) != origMethod, @"hä?");
    }
    
    NSAssert (origMethod != newMethod, nil);
    method_exchangeImplementations (origMethod, newMethod);
}

+ (void) enumerateImplementationsOfSelector:(SEL)selector
                                  stopClass:(Class)stopClass
                                 usingBlock:(void(^)(Class implementingClass, BOOL* stop))block
{
    NSParameterAssert (selector);
    NSParameterAssert (block);
    
    BOOL stop = NO;
    for (Class iClass = self; iClass; iClass = iClass.superclass) {
        if (iClass == stopClass)
            break;
        
        unsigned int methodCount;
        Method* methodList = class_copyMethodList (iClass, &methodCount);
        for (unsigned int i = 0; i < methodCount; ++i) {
            if (method_getName(methodList[i]) == selector) {
                block (iClass, &stop);
                break;
            }
        }
        free (methodList);

        if (stop)
            break;
    }
}

- (void) enumerateImplementationsOfSelector:(SEL)selector
                                  stopClass:(Class)stopClass
                                 usingBlock:(void(^)(Class implementingClass, BOOL* stop))block
{
    [self.class enumerateImplementationsOfSelector:selector stopClass:stopClass usingBlock:block];
}

+ (BOOL)enumerateProtocolsRecursively:(BOOL)recurse
                           usingBlock:(PWProtocolEnumerator)block
{
    NSParameterAssert(block);

    BOOL stopped = NO;
    unsigned int count;
    __unsafe_unretained Protocol** protocols = class_copyProtocolList(self, &count);
    if(protocols)
    {
        for(NSUInteger index=0; index<count; index++)
        {
            Protocol* iProtocol = protocols[index];
            block(iProtocol, &stopped);
            if(stopped)
                break;
            if(recurse)
            {
                stopped = PWEnumerateSubProtocolsOfProtocol(iProtocol, YES, block);
                if(stopped)
                    break;
            }
        }
        free(protocols);
    }
    return stopped;
}

+ (void)enumerateSubclassesAndProtocolsUsingBlock:(PWClassAndProtocolEnumerator)block
{
    NSParameterAssert(block);

    BOOL stopped = NO;
    block(self, nil, &stopped);
    if(stopped)
        return;

    stopped = [self enumerateProtocolsRecursively:YES
                                       usingBlock:^(Protocol* iProtocol, BOOL* stop) {
                                           block(Nil, iProtocol, stop);
                                       }];
    if(!stopped)
        [self.superclass enumerateSubclassesAndProtocolsUsingBlock:block];
}

+ (void)enumeratePropertiesUsingBlock:(PWPropertyEnumerator)block
{
    NSParameterAssert(block);

    unsigned int count;
    objc_property_t* properties = class_copyPropertyList(self, &count);
    if(properties)
    {
        BOOL stop = NO;
        for(NSUInteger index=0; index<count; index++)
        {
            block(properties[index], &stop);
            if(stop)
                break;
        }
        free(properties);
    }
}

#pragma mark - Tree Enumeration

- (void) enumerateTreeDepthFirstWithChildrenAccessor:(id<PWEnumerable>(^)(id parent))childrenAccessor
                                      beforeChildren:(void(^)(id item, BOOL* skipChildren, BOOL* stop))beforeChildren
                                       afterChildren:(void(^)(id item, BOOL* stop))afterChildren
{
    NSParameterAssert (childrenAccessor);

    BOOL stop = NO;
    [self enumerateTreeDepthFirstWithChildrenAccessor:childrenAccessor
                                       beforeChildren:beforeChildren
                                        afterChildren:afterChildren
                                                 stop:&stop];
}

- (void) enumerateTreeDepthFirstWithChildrenAccessor:(id<PWEnumerable>(^)(id parent))childrenAccessor
                                      beforeChildren:(void(^)(id item, BOOL* skipChildren, BOOL* stop))beforeChildren
                                       afterChildren:(void(^)(id item, BOOL* stop))afterChildren
                                                stop:(BOOL*)stop
{
    NSParameterAssert (stop);
    
    BOOL skipChildren = NO;
    if (beforeChildren)
        beforeChildren (self, &skipChildren, stop);
    
    if (skipChildren || *stop)
        return;
    
    for (NSObject* iItem in childrenAccessor (self)) {
        [iItem enumerateTreeDepthFirstWithChildrenAccessor:childrenAccessor
                                            beforeChildren:beforeChildren
                                             afterChildren:afterChildren
                                                      stop:stop];
        if (*stop)
            return;
    }

    if (afterChildren)
        afterChildren (self, stop);
}

@end

#pragma mark - Runtime tool functions

// Allows nil parameters, considering nil less than anything else.
NSComparisonResult PWCompareObjects(id<PWComparing> objA, id<PWComparing> objB)
{
    if (objA == objB)
        return NSOrderedSame;
    if (!objA)
        return NSOrderedAscending;
    if (!objB)
        return NSOrderedDescending;
    return [objA compare:objB];
}

id PWClassOrProtocolFromString(NSString* string)
{
    NSCParameterAssert(string);
    id result = NSClassFromString(string);
    return result ? result : NSProtocolFromString(string);
}

NSString* PWStringFromClass(Class aClass)
{
    return NSStringFromClass([[aClass class] class]);
}

NSString* PWStringFromClassOrProtocol(id classOrProtocol)
{
    NSCParameterAssert(classOrProtocol);
    return PWPointerIsProtocol(classOrProtocol) ? NSStringFromProtocol(classOrProtocol) : PWStringFromClass(classOrProtocol);
}

BOOL PWEnumerateSubProtocolsOfProtocol(Protocol* protocol, BOOL recurse, PWProtocolEnumerator block)
{
    NSCParameterAssert(protocol);
    NSCParameterAssert(block);

    BOOL stopped = NO;
    unsigned int count;
    __unsafe_unretained Protocol** subProtocols = protocol_copyProtocolList(protocol, &count);
    if(subProtocols)
    {
        for(NSUInteger index=0; index<count; index++)
        {
            Protocol* subProtocol = subProtocols[index];
            block(subProtocol, &stopped);
            if(stopped)
                break;
            if(recurse)
            {
                stopped = PWEnumerateSubProtocolsOfProtocol(subProtocol, YES, block);
                if(stopped)
                    break;
            }
        }
        free(subProtocols);
    }
    return stopped;
}

void PWEnumeratePropertiesOfProtocol(Protocol* protocol, PWPropertyEnumerator block)
{
    NSCParameterAssert(protocol);
    NSCParameterAssert(block);

    unsigned int count;
    objc_property_t* properties = protocol_copyPropertyList(protocol, &count);
    if(properties)
    {
        BOOL stop = NO;
        for(NSUInteger index=0; index<count; index++)
        {
            block(properties[index], &stop);
            if(stop)
                break;
        }
        free(properties);
    }
}

BOOL PWCopyInstanceMethod (Class sourceClass, SEL sourceSelector, Class targetClass, SEL targetSelector)
{
    NSCParameterAssert (sourceClass);
    NSCParameterAssert (sourceSelector);
    NSCParameterAssert (targetClass);
    NSCParameterAssert (targetSelector);

    Method method = class_getInstanceMethod (sourceClass, sourceSelector);
    if (!method)
        return NO;
    return class_addMethod (targetClass,
                            targetSelector,
                            method_getImplementation (method),
                            method_getTypeEncoding (method));
}

BOOL PWCopyClassMethod (Class sourceClass, SEL sourceSelector, Class targetClass, SEL targetSelector)
{
    NSCParameterAssert (sourceClass);
    NSCParameterAssert (sourceSelector);
    NSCParameterAssert (targetClass);
    NSCParameterAssert (targetSelector);
    
    Method method = class_getClassMethod (sourceClass, sourceSelector);
    if (!method)
        return NO;
    Class targetMetaClass = objc_getMetaClass (class_getName (targetClass));
    NSCAssert (targetMetaClass, nil);   // should never fail if 'targetClass' is a valid class
    return class_addMethod (targetMetaClass,
                            targetSelector,
                            method_getImplementation (method), 
                            method_getTypeEncoding (method));
}

BOOL PWCopyMethod (Class sourceClass, SEL sourceSelector, Class targetClass, SEL targetSelector, BOOL isClassMethod)
{
    NSCParameterAssert (sourceClass);
    NSCParameterAssert (sourceSelector);
    NSCParameterAssert (targetClass);
    NSCParameterAssert (targetSelector);
    
    Method method;
    if (isClassMethod) {
        targetClass = objc_getMetaClass (class_getName (targetClass));
        NSCAssert (targetClass, nil);   // should never fail if passed in 'targetClass' is a valid class
        method = class_getClassMethod (sourceClass, sourceSelector);
    } else
        method = class_getInstanceMethod (sourceClass, sourceSelector);

    if (!method)
        return NO;
    return class_addMethod (targetClass,
                            targetSelector,
                            method_getImplementation (method),
                            method_getTypeEncoding (method));
}

const char *__crashreporter_info__ = NULL;
asm(".desc ___crashreporter_info__, 0x10");

void PWNoteInCrashReportForPerformingBlock(NSString* note, void (^block)(void))
{
    NSCParameterAssert(note);
    NSCParameterAssert(block);

    const char* saved = __crashreporter_info__;
    __crashreporter_info__ = note.UTF8String;
    block();
    __crashreporter_info__ = saved;
}

NSString* PWCurrentNoteForCrashReports()
{
    if(__crashreporter_info__)
        return @(__crashreporter_info__);
    else
        return nil;
}
