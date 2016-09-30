//
//  NSMutableDictionary-PWExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 27.03.09.
//
//

// as mutable dictionary object literals line dict[key] cannot handle assignments of nil values:
#define PWDictSetObject(dict, key, value) \
    do {id __dict_value = value; if (__dict_value) [dict setObject:__dict_value forKey:key]; } while(0);

NS_ASSUME_NONNULL_BEGIN

@interface NSMutableDictionary<KeyType, ObjectType> (PWExtensions)

- (void)mergeWithDictionary:(nullable NSDictionary*)dictionary;
- (nullable ObjectType)popObjectForKey:(NSString*)key;

@end

NS_ASSUME_NONNULL_END
