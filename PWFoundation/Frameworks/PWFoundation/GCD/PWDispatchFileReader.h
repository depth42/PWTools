//
//  PWDispatchFileReader.h
//  PWFoundation
//
//  Created by Frank Illenberger on 20.07.09.
//
//

#import <PWFoundation/PWDispatchSource.h>

NS_ASSUME_NONNULL_BEGIN

@interface PWDispatchFileReader : PWDispatchSource 

- (instancetype) initWithFileHandle:(NSFileHandle*)handle 
                  onQueue:(id<PWDispatchQueueing>)queue;

@property (nonatomic, readonly, strong) NSFileHandle* fileHandle;
@property (nonatomic, readonly)         NSUInteger    availableBytes;
@end

NS_ASSUME_NONNULL_END
