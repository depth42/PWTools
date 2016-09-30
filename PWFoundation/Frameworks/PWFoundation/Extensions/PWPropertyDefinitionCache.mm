//
//  PWPropertyDefinitionCache.m
//  PWFoundation
//
//  Created by Frank Illenberger on 13.06.13.
//
//

#import "PWPropertyDefinitionCache.h"
#import "PWDispatch.h"
#import "NSObject-PWExtensions.h"

#import <unordered_map>
#import <objc/message.h>

@implementation PWPropertyDefinitionCache
{
    PWDispatchQueue* _dispatchQueue;
    NSMapTable*      _definitionsByClass;   // Class -> NSDictionary (propertyName -> protocol* or Class)
}

- (id)init
{
    if(self = [super init])
    {
        _dispatchQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWLocalizerCache"];
        _definitionsByClass = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

+ (PWPropertyDefinitionCache*)sharedCache
{
    static PWPropertyDefinitionCache* cache;
    PWDispatchOnce(^{
        cache = [[PWPropertyDefinitionCache alloc] init];
    });
    return cache;
}

- (void)definitionClass:(Class*)outDefinitionClass
             orProtocol:(Protocol**)outDefinitionProtocol
    forPropertyWithName:(NSString*)propertyName
                inClass:(Class)theClass
{
    NSParameterAssert(outDefinitionClass);
    NSParameterAssert(outDefinitionProtocol);
    NSParameterAssert(propertyName);

    // Get rid of automatic classes like for KVO
    theClass = theClass.class.class;

    NSDictionary* definitionByPropertyName = [_definitionsByClass objectForKey:theClass];
    if(!definitionByPropertyName)
    {
        definitionByPropertyName = [self definitionsForClass:theClass];
        [_definitionsByClass setObject:definitionByPropertyName forKey:theClass];
    }

    id definition = definitionByPropertyName[propertyName];
    if(PWPointerIsProtocol(definition))
    {
        *outDefinitionClass = Nil;
        *outDefinitionProtocol = definition;
    }
    else
    {
        *outDefinitionClass = definition;
        *outDefinitionProtocol = nil;
    }
}

- (NSDictionary*)definitionsForClass:(Class)theClass
{
    NSParameterAssert(theClass);

    Class stopClass = NSObject.class;
    NSMutableDictionary* definitions = [NSMutableDictionary dictionary];
    [theClass enumerateSubclassesAndProtocolsUsingBlock:^(Class iClass, Protocol* iProtocol, BOOL* stop) {
        if(iClass != stopClass)
        {
            if(iClass)
                [iClass enumeratePropertiesUsingBlock:^(struct objc_property *iProperty, BOOL* stop2) {
                    NSString* name = @(property_getName(iProperty));
                    definitions[name] = iClass;
                }];
            else
                PWEnumeratePropertiesOfProtocol(iProtocol, ^(struct objc_property *iProperty, BOOL* stop2) {
                    NSString* name = @(property_getName(iProperty));
                    definitions[name] = iProtocol;
                });
        }
    }];
    return definitions;
}

@end
