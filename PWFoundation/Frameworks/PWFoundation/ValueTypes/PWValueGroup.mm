//
//  PWValueGroup.m
//  PWFoundation
//
//  Created by Frank Illenberger on 13.04.13.
//
//

#import "PWValueGroup.h"
#import "PWAsserts.h"
#import "NSNull-PWExtensions.h"
#import <vector>

typedef enum
{
    PWValueGroupItemKindValue,
    PWValueGroupItemKindGroup
} PWValueGroupItemKind;

namespace PW
{
    struct ValueGroupItem
    {
        id                      item;
        PWValueCategory         category;
        PWValueGroupItemKind    kind;
    };
}

using namespace PW;

@implementation PWValueGroup
{
    std::vector<ValueGroupItem> _items;
}

- (instancetype)init
{
    if(self = [super init])
    {
        _type = PWValueGroupTypeRoot;
    }
    return self;
}

@synthesize isImmutable = _isImmutable;

- (void)makeImmutable
{
    if(!_isImmutable)
    {
         _isImmutable = YES;
        [self enumerateWithCategories:PWValueCategoryMaskAll
                           usingBlock:^(id iValue, PWValueGroup *iGroup, PWValueCategory iCategory, BOOL *stop)
         {
             [iGroup makeImmutable];
         }];
    }
}

- (id)mutableCopyWithZone:(NSZone*)zone
{
    PWValueGroup* copy = [[self.class alloc] init];
    copy->_type = _type;
    copy->_name = _name;
    copy->_items = _items;
    return copy;
}

- (id)copyWithZone:(NSZone*)zone
{
    if(_isImmutable)
        return self;
    else
    {
        id copy = [self mutableCopyWithZone:zone];
        [copy makeImmutable];
        return copy;
    }
}

- (void)assertMutability
{
    if(_isImmutable)
        [NSException raise:NSInternalInconsistencyException format:@"%@ is immutable", self];
}

- (void)setName:(NSString*)name
{
    [self assertMutability];
    _name = [name copy];
}

- (void)setType:(PWValueGroupType)type
{
    [self assertMutability];
    _type = type;
}

- (void)addValue:(id)value withCategory:(PWValueCategory)category;
{
    [self assertMutability];
    _items.push_back({value, category, PWValueGroupItemKindValue});
 }

- (void)addGroup:(PWValueGroup*)group withCategory:(PWValueCategory)category
{
    NSParameterAssert(group);
    
    [self assertMutability];
    _items.push_back({group, category, PWValueGroupItemKindGroup});
    if(group.type == PWValueGroupTypeRoot)
    {
        PWReleaseAssert(!group.isImmutable, @"You cannot add a value group of type root as a sub-group");
        group.type = PWValueGroupTypeWeak;
    }
}

- (void)addValue:(id)value
{
    [self addValue:value withCategory:PWValueCategoryBasic];
}

- (void)addValues:(id<PWEnumerable>)values
{
    for(id value in values)
        [self addValue:value withCategory:PWValueCategoryBasic];
}

- (void)addGroup:(PWValueGroup*)group
{
    [self addGroup:group withCategory:PWValueCategoryBasic];
}

- (void)enumerateWithCategories:(PWValueCategoryMask)categories
                     usingBlock:(void (^)(id iValue, PWValueGroup* iGroup, PWValueCategory iCategory, BOOL* stop))block
{
    [self _enumerateWithCategories:categories deep:NO usingBlock:block];
}

- (void)deepEnumerateWithCategories:(PWValueCategoryMask)categories
                      usingBlock:(void (^)(id iValue, PWValueGroup* iGroup, PWValueCategory iCategory, BOOL* stop))block
{
    [self _enumerateWithCategories:categories deep:YES usingBlock:block];
}

- (void)_enumerateWithCategories:(PWValueCategoryMask)categories
                            deep:(BOOL)deep
                      usingBlock:(void (^)(id iValue, PWValueGroup* iGroup, PWValueCategory iCategory, BOOL* stop))block
{
    NSParameterAssert(block);
    
    BOOL stop = NO;
    for(auto iItem : _items)
    {
        PWValueCategory category = iItem.category;
        if((categories & 1<<category) > 0)
        {
            id value;
            PWValueGroup* group;
            if(iItem.kind == PWValueGroupItemKindValue)
                value = iItem.item;
            else
                group = iItem.item;

            block(value, group, category, &stop);

            if(group && deep)
                [group _enumerateWithCategories:categories
                                           deep:deep
                                     usingBlock:block];
            if(stop)
                break;
        }
    }
}

- (BOOL)deepEnumerateValuesWithCategories:(PWValueCategoryMask)categories
                               usingBlock:(void (^)(id iValue, PWValueCategory iCategory, BOOL* stop))block
{
    NSParameterAssert(block);

    BOOL enumeratedAll = YES;
    BOOL stop = NO;
    for(auto iItem : _items)
    {
        PWValueCategory category = iItem.category;
        if((categories & 1<<category) > 0)
        {
            if(iItem.kind == PWValueGroupItemKindValue)
            {
                block(iItem.item, category, &stop);
                if(stop)
                {
                    enumeratedAll = NO;
                    break;
                }
            }
            else
            {
                PWValueGroup* group = iItem.item;
                if(![group deepEnumerateValuesWithCategories:categories usingBlock:block])
                {
                    enumeratedAll = NO;
                    break;
                }
            }
        }
    }

    return enumeratedAll;
}

- (NSUInteger)count
{
    return _items.size();
}

- (NSArray*)deepValues
{
    NSMutableArray* values = [NSMutableArray array];
    [self deepEnumerateValuesWithCategories:PWValueCategoryMaskAll
                                 usingBlock:^(id iValue, PWValueCategory iCategory, BOOL *stop)
     {
         [values addObject:PWNullForNil(iValue)];
     }];
    return values;
}

+ (PWValueGroup*)groupWithValues:(id<PWEnumerable>)values
{
    PWValueGroup* group = [[PWValueGroup alloc] init];
    for(id iValue in values)
        [group addValue:PWNilForNull(iValue)];
    [group makeImmutable];
    return group;
}

- (BOOL)deepContainsValue:(id)value category:(PWValueCategory*)outCategory
{
    __block BOOL result = NO;
    [self deepEnumerateValuesWithCategories:PWValueCategoryMaskAll
                                 usingBlock:^(id iValue, PWValueCategory iCategory, BOOL *stop) {
                                     if([iValue isEqual:value])
                                     {
                                         if(outCategory)
                                             *outCategory = iCategory;
                                         *stop = YES;
                                         result = YES;
                                     }
                                 }];
    return result;
}

- (BOOL)deepContainsValue:(id)value
{
    return [self deepContainsValue:value category:NULL];
}

- (BOOL)deepContainsValueInCategory:(PWValueCategory)category
{
    __block BOOL result = NO;
    [self deepEnumerateValuesWithCategories:PWValueCategoryMaskAll
                                 usingBlock:^(id iValue, PWValueCategory iCategory, BOOL *stop) {
                                     if(iCategory == category)
                                     {
                                         *stop = YES;
                                         result = YES;
                                     }
                                 }];
    return result;
}

@end
