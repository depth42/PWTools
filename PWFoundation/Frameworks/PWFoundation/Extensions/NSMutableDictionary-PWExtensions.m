//
//  NSMutableDictionary-PWExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 27.03.09.
//
//

#import "NSMutableDictionary-PWExtensions.h"
#import "NSDictionary-PWExtensions.h"

@implementation NSMutableDictionary (PWExtensions)

- (void)mergeWithDictionary:(NSDictionary*)dictionary
{
    if(!dictionary)
        return;
    
    Class dictionaryClass = [NSDictionary class];
    NSMutableDictionary *dict = [dictionary deepMutableCopy];
    for(NSString *key in dict)
    {
        id object = dict[key];
        if(![object isKindOfClass:dictionaryClass])
            self[key] = object;
        else
        {
            id myObject = self[key];
            if(!myObject)
                self[key] = object;
            else if([myObject isKindOfClass:dictionaryClass])
                [myObject mergeWithDictionary:object];
        }
    }
}

- (id)popObjectForKey:(NSString*)key
{
    id obj = self[key];
    if(obj)
        [self removeObjectForKey:key];
    return obj;
}
@end
