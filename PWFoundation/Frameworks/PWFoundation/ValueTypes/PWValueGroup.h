//
//  PWValueGroup.h
//  PWFoundation
//
//  Created by Frank Illenberger on 13.04.13.
//
//

#import <PWFoundation/PWMutability.h>
#import <PWFoundation/PWEnumerable.h>

typedef NS_ENUM(unsigned int, PWValueGroupType)
{
    PWValueGroupTypeRoot,           // Only the root group returned by the presetValuesModeForContext:... has to be of this type.
    PWValueGroupTypeWeak,           // In menus, a weak sub-group is turned into blocks with separators in between
    PWValueGroupTypeStrong          // In menus, a strong sub-group is turned into a sub-menu
};

typedef NS_ENUM(unsigned int, PWValueCategory)
{
    PWValueCategoryBasic    = 0,    // Default category for values
    PWValueCategoryExtended = 1     // In menus, values of this category are only displayed after the user clicked the "more" entry at the bottom of the menu
};

typedef NS_OPTIONS(NSUInteger, PWValueCategoryMask)
{
    PWValueCategoryMaskBasic    = 1<<PWValueCategoryBasic,
    PWValueCategoryMaskExtended = 1<<PWValueCategoryExtended,
    PWValueCategoryMaskAll      = PWValueCategoryMaskBasic | PWValueCategoryMaskExtended
};

// A value group holds the preset values which are returned by the out-argument
// of -[PWValueType presetValuesModeForContext:object:options:values:]
// Commonly, it is sufficient to create a root group from a simple list of values via +groupWithValues:
// Values can be logically grouped by adding sub-groups.
@interface PWValueGroup : NSObject <PWMutability>

// Returns mutable empty root group
- (instancetype)init;

// Returns immutable group containing given values as items of PWValueCategoryBasic
+ (PWValueGroup*)groupWithValues:(id <PWEnumerable>)values;

// Defaults to root, is automatically changed to weak if added as item to other group
@property (nonatomic, readwrite)        PWValueGroupType    type;

// Defaults to nil. Used for presenting the group to the user.
@property (nonatomic, readwrite, copy)  NSString*           name;              

- (void)addValue:(id)value withCategory:(PWValueCategory)category;
- (void)addGroup:(PWValueGroup*)group withCategory:(PWValueCategory)category;

// Convenience methods, add with category PWValueCategoryBasic
- (void)addValue:(id)value;
- (void)addValues:(id<PWEnumerable>)values;
- (void)addGroup:(PWValueGroup*)group;

// For every block invocation, if iGroup is != nil then iValue == nil.
// The values and groups are provided in the order in which they were added.
- (void)enumerateWithCategories:(PWValueCategoryMask)categories
                     usingBlock:(void (^)(id iValue, PWValueGroup* iGroup, PWValueCategory iCategory, BOOL* stop))block;

// Same as above but deep.
- (void)deepEnumerateWithCategories:(PWValueCategoryMask)categories
                         usingBlock:(void (^)(id iValue, PWValueGroup* iGroup, PWValueCategory iCategory, BOOL* stop))block;

// Returns false if it has been stopped
- (BOOL)deepEnumerateValuesWithCategories:(PWValueCategoryMask)categories
                               usingBlock:(void (^)(id iValue, PWValueCategory iCategory, BOOL* stop))block;

- (BOOL)deepContainsValue:(id)value;
- (BOOL)deepContainsValue:(id)value category:(PWValueCategory*)outCategory;
- (BOOL)deepContainsValueInCategory:(PWValueCategory)category;

// Returns the total shallow number of values and groups.
@property (nonatomic, readonly)         NSUInteger          count;

// Returns all values, recursively depth-first
@property (nonatomic, readonly, copy)   NSArray*            deepValues;         

@end
