//
//  PWPropertyDefinitionCache.h
//  PWFoundation
//
//  Created by Frank Illenberger on 13.06.13.
//
//

@interface PWPropertyDefinitionCache : NSObject

+ (PWPropertyDefinitionCache*)sharedCache;

- (void)definitionClass:(Class*)outDefinitionClass
             orProtocol:(Protocol**)outDefinitionProtocol
    forPropertyWithName:(NSString*)propertyName
                inClass:(Class)theClass;

@end
