//
//  NSDictionary-PWExtensions.h
//  Merlin
//
//  Created by Frank Illenberger on 22.09.04.
//
//

NS_ASSUME_NONNULL_BEGIN

// Note: XML-Coding of dictionaries is supported for string keys only. And of course all values must be XML-codable
// themselves.

@interface NSDictionary<KeyType, ObjectType> (PWExtensions)

@property (nonatomic, readonly, copy) NSMutableDictionary<KeyType,ObjectType> * _Nonnull deepMutableCopy;
- (nullable id)valueForKeyPath:(NSString*)keyPath fallBackDictionary:(nullable NSDictionary*)fallBackDictionary;
- (NSString*)queryStringWithEncoding:(NSStringEncoding)encoding;
- (BOOL)all:(BOOL (^)(ObjectType))block;
- (BOOL)any:(BOOL (^)(ObjectType))block;
- (nullable ObjectType)match:(BOOL (^)(ObjectType))block;
- (NSArray<ObjectType>*)select:(BOOL (^)(ObjectType))block;

// Returns the dictionary itself if it contains objects or nil if it is empty.
@property (nonatomic, readonly, copy) NSDictionary * _Nullable nilIfEmpty;

// Returns a string in the following format: <key><keyValueSeparator><value><dataSeparator>...
// The keys inside the dictionary must be strings. The values inside the dictionary must be strings or arrays with only strings in it.
- (NSString*)stringWithKeyValueSeparator:(NSString*)keyValueSeparator dataSeparator:(NSString*)dataSeparator;

// Returns nil if the receiver does not contain any key.
// Otherwise it returns a new dictionary with keys and values that are in keys.
- (nullable NSDictionary<KeyType, ObjectType>*) dictionaryByFilteringKeys:(NSArray<KeyType>*)keys;

// Returns a new dictionary with every key/value pair for which the block returns true.
- (nullable NSDictionary<KeyType, ObjectType>*) reducedDictionary:(BOOL (^)(id key, id value))block;

- (NSDictionary<KeyType, ObjectType>*) dictionaryByAddingEntriesFromDictionary:(nullable NSDictionary<KeyType, ObjectType>*)dictionary;
- (NSDictionary<KeyType, ObjectType>*) dictionaryByRemovingObjectsForKeys:(nullable NSArray<KeyType>*)keys;

+ (NSDictionary<KeyType, ObjectType>*) dictionaryBySettingObject:(ObjectType)object
                                                          forKey:(KeyType<NSCopying>)key
                                                    inDictionary:(nullable NSDictionary<KeyType, ObjectType>*)dictionary;

// Returns [dictionary mutableCopy] if dictionary is given and a new mutable dictionary else.
+ (NSMutableDictionary<KeyType, ObjectType>*) ensureMutableCopyOfDictionary:(nullable NSDictionary<KeyType, ObjectType>*)dictionary;

@end

NS_ASSUME_NONNULL_END
