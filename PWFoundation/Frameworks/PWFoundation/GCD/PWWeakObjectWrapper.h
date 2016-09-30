//
//  PWWeakObjectWrapper.h
//  PWFoundation
//
//  Created by Frank Illenberger on 07.09.10.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Acts as a wrapper that weakly holds any object. Can be used
// inside blocks to prevent the block from retaining a heavy object, for example in combination
// with PWDispatchTimer

@interface PWWeakObjectWrapper : NSObject 

- (instancetype)initWithObject:(id)object;

@property (nonatomic, readonly, nullable) __weak id object;

@end

NS_ASSUME_NONNULL_END
