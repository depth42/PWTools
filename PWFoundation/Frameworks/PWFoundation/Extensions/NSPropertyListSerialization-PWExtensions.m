//
//  NSPropertyListSerialization-PWExtensions.m
//  PWFoundation
//
//  Created by Andreas Känner on 13.11.15.
//
//

#import "NSPropertyListSerialization-PWExtensions.h"
#import "NSArray-PWExtensions.h"
#import "NSObject-PWExtensions.h"
#import "NSDictionary-PWExtensions.h"

NS_ASSUME_NONNULL_BEGIN

NSString* const PWUnserializableObjectClassName = @"PWObjectClass";

@implementation NSPropertyListSerialization (PWExtensions)

+ (NSData *)dataWithPropertyList:(id)plist
                          format:(NSPropertyListFormat)format
                         options:(NSPropertyListWriteOptions)opt
                           error:(out NSError**)outError
         transformUnserializable:(PWUnserializableTransformBlock __nullable) block
{
    PWParameterAssert([plist isKindOfClass:NSArray.class] || [plist isKindOfClass:NSDictionary.class]);

    if(block)
    {
        if([plist isKindOfClass:NSArray.class])
            plist = [self makeArraySerializable:(NSArray*)plist usingBlock:block];
        else if ([plist isKindOfClass:NSDictionary.class])
            plist = [self makeDictionarySerializable:(NSDictionary*)plist usingBlock:block];
    }
    return [self dataWithPropertyList:plist format:format options:opt error:outError];
}


+ (NSArray*) makeArraySerializable:(NSArray*)array usingBlock:(PWUnserializableTransformBlock) block
{
    PWParameterAssert(array);
    PWParameterAssert(block);

    return [array mapWithoutNull:^id (id _Nonnull value) {
        return [self  makeValueSerializable:value key:nil usingBlock:block];
    }];
}

+ (NSDictionary*) makeDictionarySerializable:(NSDictionary*)dictionary usingBlock:(PWUnserializableTransformBlock) block
{
    PWParameterAssert(dictionary);
    PWParameterAssert(block);

    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL* stop) {
        result[key] = [self makeValueSerializable:value key:key usingBlock:block];
    }];
    return result;
}

+ (nullable id) makeValueSerializable:(id)value key:(NSString* _Nullable)key usingBlock:(PWUnserializableTransformBlock) block
{
    PWParameterAssert(value);
    PWParameterAssert(!key || [key isKindOfClass:NSString.class]);
    PWParameterAssert(block);
    
    if([self pwValueIsImmediatelySerializable:value])
        return value;
    else if([value isKindOfClass:NSArray.class])
    {
        NSArray* newArray = [self makeArraySerializable:value usingBlock:block];
        return newArray.count > 0 ? newArray : nil;
    }
    else if([value isKindOfClass:NSDictionary.class])
    {
        NSDictionary* newDictionary = [self makeDictionarySerializable:value usingBlock:block];
        return newDictionary.count > 0 ? newDictionary : nil;
    }
    NSDictionary* result = block(key, value);
    if(result)
        result = [result dictionaryByAddingEntriesFromDictionary:@{PWUnserializableObjectClassName:[value className]}];
    return result;
}

+ (BOOL) pwValueIsImmediatelySerializable:(id)value
{
    PWParameterAssert(value);

    return    [value isKindOfClass:NSData.class]
           || [value isKindOfClass:NSString.class]
           || [value isKindOfClass:NSDate.class]
           || [value isKindOfClass:NSNumber.class];
}

@end

NS_ASSUME_NONNULL_END
