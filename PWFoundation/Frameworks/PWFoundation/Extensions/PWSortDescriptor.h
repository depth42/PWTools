//
//  PWSortDescriptor.h
//  Merlin
//
//  Created by Frank Illenberger
//
//

#import <PWFoundation/PWPListCoding.h>

typedef enum PWSortDescriptorsComparisonResult
{
    PWSortDescriptorsAreEqual       =  1,
    PWSortDescriptorsAreInverted    = -1,
    PWSortDescriptorsAreInequal     =  0
} PWSortDescriptorsComparisonResult;

@interface PWSortDescriptor : NSObject <NSCoding, PWPListCoding>

@property (nonatomic, readonly, copy)   NSString*  keyPath;
@property (nonatomic, readonly)         BOOL       ascending;
@property (nonatomic, readonly, copy)   NSSet*     objectClasses;

- (instancetype)initWithKeyPath:(NSString*)keyPath            // may not be nil
            ascending:(BOOL)ascending
        objectClasses:(NSSet*)objectClasses;        // if nil, descriptor may be applied to objects of all classes

- (NSDictionary*)pListRepresentationWithObjectClasses:(BOOL)withObjectClasses;

- (id)valueForObject:(id)object;                    // returns valueForKeyPath:keyPath if the objects is of one of the classes in objectClasses, or objectClasses is nil. Nil otherwise

@property (nonatomic, readonly, strong) PWSortDescriptor *reversedSortDescriptor;

- (PWSortDescriptorsComparisonResult)compareToSortDescriptor:(PWSortDescriptor*)descriptor;

+ (PWSortDescriptorsComparisonResult)compareSortDescriptors:(NSArray*)descriptorsA 
                                            withDescriptors:(NSArray*)descriptorsB;

+ (PWSortDescriptor*)sortDescriptorWithKeyPath:(NSString*)keyPath 
                                     ascending:(BOOL)ascending
                                 objectClasses:(NSSet*)objectClasses;

+ (PWSortDescriptor*)sortDescriptorWithKeyPath:(NSString*)keyPath 
                                     ascending:(BOOL)ascending;

+ (NSArray*)descriptorsMatchingObjectClass:(Class)objectClass
                             inDescriptors:(NSArray*)descriptors;

+ (NSArray*)descriptorsNotMatchingObjectClass:(Class)objectClass
                                inDescriptors:(NSArray*)descriptors;
@end
