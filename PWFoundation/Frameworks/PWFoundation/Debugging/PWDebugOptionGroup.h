//
//  PWDebugOptionGroup.h
//  PWFoundation
//
//  Created by Kai Brüning on 26.1.10.
//
//

#import <Foundation/Foundation.h>

@class PWDebugOption;


@interface PWDebugOptionGroup : NSObject

@property (nonatomic, readonly, copy)   NSArray<PWDebugOption*>*    options;

- (void) addOption:(PWDebugOption*)anOption;

// nil if no item with 'title' exists.
- (PWDebugOption*) optionWithTitle:(NSString*)title;

- (void) sortOptionsUsingComparator:(NSComparator)comparator;

@end

#pragma mark -

extern NSString* const PWDebugOptionsEnabledKey;

@interface PWRootDebugOptionGroup : PWDebugOptionGroup

+ (PWRootDebugOptionGroup*) createRootGroup;

@end
