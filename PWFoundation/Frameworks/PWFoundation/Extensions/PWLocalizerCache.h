//
//  PWLocalizerCache.h
//  PWFoundation
//
//  Created by Frank Illenberger on 07.05.13.
//
//

@class PWLocalizer;

typedef PWLocalizer* (^PWLocalizerCreationBlock)(Class aClass, NSString* language);

@interface PWLocalizerCache : NSObject

+ (PWLocalizerCache*)sharedCache;

// Can be called from any dispatch queue
- (PWLocalizer*)localizerForClass:(Class)aClass
                         language:(NSString*)language
                    creationBlock:(PWLocalizerCreationBlock)creationBlock;      // Creation block is called on a private dispatch queue

@end
