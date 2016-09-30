//
//  PWOrderedDictionary.h
//  PWFoundation
//
//  Created by Kai on 2.6.10.
//
//

#import <Foundation/Foundation.h>


/*
 A dictionary which remembers the order in which keys were added and enumerates in this order.
 Introduced to have control over the order in plist-based YAML exports.
 
 Removing and replacing existing keys is O(N), all other operations have the same time complexity as for
 NSMutableDictionary.
 
 Note: the immutable variant can be added when it is needed.
 */


@interface PWMutableOrderedDictionary<KeyType, ObjectType> : NSMutableDictionary

@property (nonatomic, readonly, strong) KeyType firstKey;
@property (nonatomic, readonly, strong) KeyType lastKey;

@property (nonatomic, readonly, strong) ObjectType firstObject;
@property (nonatomic, readonly, strong) ObjectType lastObject;

@end
