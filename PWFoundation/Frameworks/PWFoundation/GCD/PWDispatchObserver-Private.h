//
//  PWDispatchObserver-Private.h
//  PWFoundation
//
//  Created by Frank Illenberger on 25.07.09.
//
//

#import "PWDispatchObserver.h"

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchObserver ()
@property (nonatomic, readonly, strong) PWDispatchQueue* internalQueue;
@end

NS_ASSUME_NONNULL_END
