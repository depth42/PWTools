//
//  PWSortDescriptor.m
//  Merlin
//
//  Created by Frank Illenberger
//
//

#import "PWSortDescriptor.h"
#import "NSObject-PWExtensions.h"
#import "NSSet-PWExtensions.h"
#import "NSArray-PWExtensions.h"
#import "NSError-PWExtensions.h"
#import "PWErrors.h"
#import "PWOrderedDictionary.h"

@implementation PWSortDescriptor

@synthesize keyPath         = keyPath_;
@synthesize ascending       = ascending_;
@synthesize objectClasses   = objectClasses_;

+ (PWSortDescriptor*)sortDescriptorWithKeyPath:(NSString*)keyPath 
                                     ascending:(BOOL)ascending
                                 objectClasses:(NSSet*)objectClasses
{
    return [[PWSortDescriptor alloc] initWithKeyPath:keyPath ascending:ascending objectClasses:objectClasses];
}

+ (PWSortDescriptor*)sortDescriptorWithKeyPath:(NSString*)keyPath 
                                     ascending:(BOOL)ascending
{
    return [[PWSortDescriptor alloc] initWithKeyPath:keyPath ascending:ascending objectClasses:nil];
}

- (instancetype)initWithKeyPath:(NSString*)keyPath 
            ascending:(BOOL)ascending
        objectClasses:(NSSet*)objectClasses
{
    NSParameterAssert(keyPath);
    if(self = [super init])
    {
        keyPath_       = [keyPath copy];
        ascending_     = ascending;
        objectClasses_ = [objectClasses copy];
    }
    return self;
}

- (PWSortDescriptor*)reversedSortDescriptor
{
    return [[self.class alloc] initWithKeyPath:keyPath_
                                     ascending:!ascending_
                             objectClasses:objectClasses_];
}

- (BOOL)isObjectInClasses:(id)object
{
    BOOL result;
    if(!objectClasses_)
        result = YES;
    else
    {
        result = NO;
        for(Class aClass in objectClasses_)
        {
            if([object isKindOfClass:aClass])
            {
                result = YES;
                break;
            }
        }
    }
    return result;
}

- (id)valueForObject:(id)object
{
    return [self isObjectInClasses:object] ? [object valueForKeyPath:keyPath_] : nil;
}

- (NSArray*)objectClassesNames
{
    NSMutableArray* names = [NSMutableArray arrayWithCapacity:objectClasses_.count];
    for(Class aClass in objectClasses_)
        [names addObject:NSStringFromClass(aClass)];
    return [names sortedArrayUsingSelector:@selector(compare:)];
}

+ (NSSet*)objectClassesFromNames:(NSArray*)names
{
    NSSet* result;
    if(names.count > 0)
    {
        NSMutableSet* classes = [NSMutableSet setWithCapacity:names.count];
        for(NSString* name in names)
        {
            Class aClass = NSClassFromString(name);
            NSAssert(aClass, nil);
            [classes addObject:aClass];
        }
        result = classes;
    }
    return result;
}

+ (NSArray*)descriptorsMatchingObjectClass:(Class)objectClass
                             inDescriptors:(NSArray*)descriptors
{
    NSParameterAssert(objectClass);

    return [descriptors mapWithoutNull:^PWSortDescriptor*(PWSortDescriptor* iDesc) {
        NSSet* classes = iDesc.objectClasses;
        if(classes.count > 0 &&  ![classes any:^BOOL(Class iClass) {
            return [objectClass isSubclassOfClass:iClass];
        }])
            return nil;

        return [[PWSortDescriptor alloc] initWithKeyPath:iDesc.keyPath
                                               ascending:iDesc.ascending
                                           objectClasses:[NSSet setWithObject:objectClass]];
    }];
}

+ (NSArray*)descriptorsNotMatchingObjectClass:(Class)objectClass
                                inDescriptors:(NSArray*)descriptors
{
    NSParameterAssert(objectClass);

    return [descriptors select:^BOOL(PWSortDescriptor* iDesc) {
        NSSet* classes = iDesc.objectClasses;
        if(classes.count == 0)  // a descriptor without classes matches all entities
            return NO;
        return ![classes any:^BOOL(Class iClass) {
            return [objectClass isSubclassOfClass:iClass];
        }];
    }];
}

static NSString* const KeyPathEncodingKey       = @"keyPath";
static NSString* const AscendingEncodingKey     = @"ascending";
static NSString* const ObjectClassesEncodingKey = @"objectClasses";

- (instancetype)initWithPList:(id)plist context:(id <PWValueTypeContext>)context error:(NSError**)outError
{
    if(![plist isKindOfClass:NSDictionary.class])
    {
        if(outError)
            *outError = [NSError errorWithDomain:PWErrorDomain
                                            code:PWPListCodingParsingError
                             localizationContext:nil
                                          format:@"Invalid sort descriptor plist: %@", plist];

        return nil;
    }

    id keyPath = plist[KeyPathEncodingKey];
    id ascendingObj = plist[AscendingEncodingKey];
    id classNames = plist[ObjectClassesEncodingKey];

    if(![keyPath isKindOfClass:NSString.class]
       || (ascendingObj && ![ascendingObj isKindOfClass:NSNumber.class])
       || (classNames && ![classNames isKindOfClass:NSArray.class]))
    {
        if(outError)
            *outError = [NSError errorWithDomain:PWErrorDomain
                                            code:PWPListCodingParsingError
                             localizationContext:nil
                                          format:@"Invalid sort descriptor plist: %@", plist];

        return nil;
    }
    
    return [self initWithKeyPath:keyPath
                       ascending: ascendingObj ? ((NSNumber*)ascendingObj).boolValue : YES
                   objectClasses:[self.class objectClassesFromNames:classNames]];
}

- (NSDictionary*)pListRepresentationWithObjectClasses:(BOOL)withObjectClasses
{
    PWMutableOrderedDictionary* pList = [[PWMutableOrderedDictionary alloc] init];
    [pList setValue:keyPath_ forKey:KeyPathEncodingKey];
    [pList setValue:@(ascending_) forKey:AscendingEncodingKey];
    if(withObjectClasses && objectClasses_.count > 0)
        [pList setValue:self.objectClassesNames forKey:ObjectClassesEncodingKey];
    return pList;
}

- (id)pListRepresentationWithOptions:(NSDictionary*)options context:(id <PWValueTypeContext>)context
{
    return [self pListRepresentationWithObjectClasses:YES];
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    NSParameterAssert(coder.allowsKeyedCoding);
    [coder encodeObject:keyPath_                    forKey:KeyPathEncodingKey];
    [coder encodeBool:ascending_                    forKey:AscendingEncodingKey];
    [coder encodeObject:self.objectClassesNames     forKey:ObjectClassesEncodingKey];
}

- (instancetype)initWithCoder:(NSCoder*)coder
{
    return [self initWithKeyPath:[coder decodeObjectForKey:KeyPathEncodingKey]
                       ascending:[coder decodeBoolForKey:AscendingEncodingKey]
                   objectClasses:[self.class objectClassesFromNames:[coder decodeObjectForKey:ObjectClassesEncodingKey]]];
}

- (BOOL)isEqual:(id)object
{
    if(![object isKindOfClass:[PWSortDescriptor class]])
        return NO;
    
    PWSortDescriptor* desc = object;
    return PWEqualObjects(keyPath_, desc.keyPath) && ascending_ == desc.ascending && PWEqualObjects(objectClasses_, desc.objectClasses);
}

- (NSUInteger)hash
{
    NSUInteger hash = 17;
    hash = 37 * hash + keyPath_.hash;
    hash = 37 * hash + ascending_;
    hash = 37 * hash + objectClasses_.hash;
    return hash;
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@ keyPath: %@ ascending: %d objectClasses:%@", super.description, keyPath_, ascending_, objectClasses_];
}

- (PWSortDescriptorsComparisonResult)compareToSortDescriptor:(PWSortDescriptor*)descriptor
{
    PWSortDescriptorsComparisonResult result;
    if([descriptor.keyPath isEqual:keyPath_])
        result = ascending_ == descriptor.ascending ? PWSortDescriptorsAreEqual : PWSortDescriptorsAreInverted;
    else
        result = PWSortDescriptorsAreInequal;
    return result;
}

+ (PWSortDescriptorsComparisonResult)compareSortDescriptors:(NSArray*)descriptorsA 
                                            withDescriptors:(NSArray*)descriptorsB
{
    PWSortDescriptorsComparisonResult result = PWSortDescriptorsAreInequal;
    NSUInteger count = MIN(descriptorsA.count, descriptorsB.count);
    for(NSUInteger index=0; index<count; index++)
    {
        PWSortDescriptor* descA = descriptorsA[index];
        PWSortDescriptor* descB = descriptorsB[index];
        PWSortDescriptorsComparisonResult descResult = [descA compareToSortDescriptor:descB];
        if(index==0)
            result = descResult;
        else if(result != descResult)
            result = PWSortDescriptorsAreInequal;
        if(result == PWSortDescriptorsAreInequal)
            break;
    }
    return result;  
}

@end
