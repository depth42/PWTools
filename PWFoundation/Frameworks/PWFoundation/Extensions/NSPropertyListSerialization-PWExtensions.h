//
//  NSPropertyListSerialization-PWExtensions.h
//  PWFoundation
//
//  Created by Andreas Känner on 13.11.15.
//
//

NS_ASSUME_NONNULL_BEGIN

extern NSString* const PWUnserializableObjectClassName;

// The key is just a hint for the code inside the block and it is only available
// if a dictionary is serialized.
typedef NSDictionary* _Nullable  (^PWUnserializableTransformBlock)(id key, id noneSerializableValue);

@interface NSPropertyListSerialization (PWExtensions)

// In addition to the original method this one accepts an optional block which is
// called for unserializable values. If the block returns nil, unserializable values are just skipped.
// Return a serializable dictionary for the given value if you want the value to
// be included in the serialized data. If you do so, the class of the unserializable
// object is automatically added to the dictionary under the key PWUnserializableObjectClass.
+ (NSData *)dataWithPropertyList:(id)plist
                          format:(NSPropertyListFormat)format
                         options:(NSPropertyListWriteOptions)opt
                           error:(out NSError**)outError
         transformUnserializable:(PWUnserializableTransformBlock __nullable) block;

+ (NSArray*) makeArraySerializable:(NSArray*)array usingBlock:(PWUnserializableTransformBlock) block;
+ (NSDictionary*) makeDictionarySerializable:(NSDictionary*)dictionary usingBlock:(PWUnserializableTransformBlock) block;

@end

NS_ASSUME_NONNULL_END
