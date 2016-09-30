//
//  PWDispatchPathObserver.m
//  PWFoundation
//
//  Created by Frank Illenberger on 06.04.16.
//
//

#import "PWDispatchPathObserver.h"

NS_ASSUME_NONNULL_BEGIN

@implementation PWDispatchPathObserver
{
    NSMutableArray<PWDispatchFileObserver*>* _segmentObservers;
}

- (instancetype)initWithFileURL:(NSURL*)URL
                      eventMask:(PWDispatchFileEventMask)mask
                        onQueue:(id<PWDispatchQueueing>)queue
                     eventBlock:(PWDispatchBlock)eventBlock
{
    NSParameterAssert(URL.isFileURL);

    if(self = [super init])
    {
        _URL = URL;
        _eventMask = mask;
        _segmentObservers = [NSMutableArray array];
        
        while(URL.path.length > 1)
        {
            PWDispatchFileObserver* observer = [[PWDispatchFileObserver alloc] initWithFileURL:URL
                                                                                     eventMask:mask
                                                                                       onQueue:queue];
            if(observer)
            {
                observer.eventBlock = eventBlock;
                [_segmentObservers addObject:observer];
            }
            URL = URL.URLByDeletingLastPathComponent;
        }
    }
    return self;
}

- (void)enable
{
    for(PWDispatchFileObserver* iObserver in _segmentObservers)
        [iObserver enable];
}

- (void)disable
{
    for(PWDispatchFileObserver* iObserver in _segmentObservers)
        [iObserver disable];
}

- (void)dispose
{
    for(PWDispatchFileObserver* iObserver in _segmentObservers)
        [iObserver cancel];
}
@end

NS_ASSUME_NONNULL_END
