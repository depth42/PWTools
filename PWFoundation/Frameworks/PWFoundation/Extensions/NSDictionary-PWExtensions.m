//
//  NSDictionary-PWExtensions.m
//  Merlin
//
//  Created by Frank Illenberger on 22.09.04.
//
//

#import "NSDictionary-PWExtensions.h"
#import "NSString-PWExtensions.h"
#import "PWErrors.h"
#import "NSError-PWExtensions.h"

@implementation NSDictionary (PWExtensions)

- (NSDictionary*)deepMutableCopy
{
    NSMutableDictionary* newDictionary = self.mutableCopy;
    // OPT: copy element by element to avoid temporary dictionary.
    NSMutableDictionary* temp = [NSMutableDictionary dictionary];
    for (id aKey in newDictionary)
    {
        id anObject = newDictionary[aKey];
        id copiedObject;
        if ([anObject respondsToSelector:@selector(deepMutableCopy)])
            copiedObject = [anObject deepMutableCopy];
        else if ([anObject conformsToProtocol:@protocol(NSMutableCopying)])
            copiedObject = [anObject mutableCopy];
        else if ([anObject conformsToProtocol:@protocol(NSCopying)])
            copiedObject = [anObject copy];
        if (copiedObject)
            temp[aKey] = copiedObject;
    }
    for(NSString* key in temp)
    {
        id value = temp[key];
        newDictionary[key] = value;
    }
    return newDictionary;
}

- (id)valueForKeyPath:(NSString *)keyPath fallBackDictionary:(NSDictionary *)fallBackDictionary
{
    id value = [self valueForKeyPath:keyPath];
    if(!value && fallBackDictionary)
        value = [fallBackDictionary valueForKeyPath:keyPath];
    return value;
}

- (NSString *)queryStringWithEncoding:(NSStringEncoding)encoding
{
    NSMutableString *result = [NSMutableString string];
    NSUInteger index=0;
    for(NSString *key in self)
    {
        NSString *value = [self[key] description];
        [result appendString:index==0 ? @"?" : @"&"];
        [result appendString:[key stringByURLEscapingWithEncoding:encoding]];
        [result appendString:@"="];
        [result appendString:[value stringByURLEscapingWithEncoding:encoding]];
        index++;
    }       
    return result;
}

- (nullable NSDictionary*)nilIfEmpty
{
    return self.count > 0 ? self : nil;
}

#pragma mark Blocks

- (BOOL)all:(BOOL (^)(id))block
{
    NSParameterAssert(block);
    for (id obj in self.objectEnumerator)
        if(!block(obj))
            return NO;
    return YES;
}

- (BOOL)any:(BOOL (^)(id))block
{
    NSParameterAssert(block);
    for (id obj in self.objectEnumerator)
        if(block(obj))
            return YES;
    return NO;
}

- (nullable id)match:(BOOL (^)(id))block
{
    NSParameterAssert(block);
    for (id obj in self.objectEnumerator)
        if (block(obj))
            return obj;
    return nil;
}

- (NSArray*)select:(BOOL (^)(id))block
{
    NSParameterAssert(block);
    NSMutableArray* result = [NSMutableArray array];
    for (id obj in self.objectEnumerator)
        if (block(obj))
            [result addObject:obj];
    return result;
}

- (NSString*)stringWithKeyValueSeparator:(NSString*)keyValueSeparator dataSeparator:(NSString*)dataSeparator
{
    NSParameterAssert(keyValueSeparator);
    NSParameterAssert(dataSeparator);
    
    NSMutableString* result  = [[NSMutableString alloc] init];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSAssert([key isKindOfClass:NSString.class], nil);
        NSAssert([value isKindOfClass:NSString.class] || ([value isKindOfClass:[NSArray class]] && [value all:^BOOL(id subvalue) {
            return [subvalue isKindOfClass:NSString.class];
        }]), nil);
        if([value isKindOfClass:[NSArray class]])
        {
            for(NSString* subvalue in value)
            {
                [result appendString:key];
                [result appendString:keyValueSeparator];
                [result appendString:subvalue];
                [result appendString:dataSeparator];
            }
        }
        else
        {
            [result appendString:key];
            [result appendString:keyValueSeparator];
            [result appendString:value];
            [result appendString:dataSeparator];
        }
    }];
    return result;
}

- (nullable NSDictionary*) dictionaryByFilteringKeys:(NSArray*)keys
{
    NSParameterAssert(keys);
    NSMutableDictionary* result;
    for (id key in keys)
    {
        id value = self[key];
        if(value)
        {
            if(!result)
                result = [NSMutableDictionary dictionary];
            result[key] = value;
        }
    }
    return result;
}

- (nullable NSDictionary*) reducedDictionary:(BOOL (^)(id key, id value))block
{
    NSParameterAssert(block);
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
       if(block(key, obj))
           result[key] = obj;
    }];
    return result.count == 0 ? nil : result;
}


- (NSDictionary*) dictionaryByAddingEntriesFromDictionary:(nullable NSDictionary*)dictionary
{
    if (!dictionary)
        return self;

    NSMutableDictionary* result = [self mutableCopy];
    [result addEntriesFromDictionary:dictionary];
    return result;
}

- (NSDictionary*) dictionaryByRemovingObjectsForKeys:(nullable NSArray*)keys
{
    if(keys.count == 0)
        return self;

    NSMutableDictionary* result = [self mutableCopy];
    [result removeObjectsForKeys:keys];
    return result;
}

+ (NSDictionary*) dictionaryBySettingObject:(id)object
                                     forKey:(id)key
                               inDictionary:(nullable NSDictionary*)dictionary
{
    if (!dictionary)
        return @{key:object};
        
    NSMutableDictionary* result = [dictionary mutableCopy];
    result[key] = object;
    return result;
}

+ (NSMutableDictionary*) ensureMutableCopyOfDictionary:(nullable NSDictionary*)dictionary
{
    return dictionary ? [dictionary mutableCopy] : [NSMutableDictionary dictionary];
}

@end
