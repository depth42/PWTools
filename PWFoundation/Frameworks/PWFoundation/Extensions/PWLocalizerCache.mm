//
//  PWLocalizerCache.m
//  PWFoundation
//
//  Created by Frank Illenberger on 07.05.13.
//
//

#import "PWLocalizerCache.h"
#import "PWDispatch.h"
#import "PWLocalizer.h"
#import <unordered_map>

namespace PW {

    struct CacheKey
    {
        Class aClass;
        NSString* language;
    };

    inline BOOL operator== (const CacheKey& k1, const CacheKey& k2)
    {
        return k1.aClass == k2.aClass && [k1.language isEqualToString:k2.language];
    }

}

using namespace PW;

namespace std {
    template<>
    class hash<CacheKey> {
    public:
        size_t operator()(const CacheKey& k) const {
            // Hash combination taken from "The Ruby Programming Language", page 224.
            size_t h =      hash<void*>()((__bridge void*)k.aClass);
            h        = 37 * h + k.language.hash;
            return h;
        }
    };
}

@implementation PWLocalizerCache
{
    PWDispatchQueue*                            _dispatchQueue;
    std::unordered_map<CacheKey, PWLocalizer*>  _cache;
}

- (id)init
{
    if(self = [super init])
    {
        _dispatchQueue = [PWDispatchQueue serialDispatchQueueWithLabel:@"PWLocalizerCache"];
    }
    return self;
}

+ (PWLocalizerCache*)sharedCache
{
    static PWLocalizerCache* cache;
    PWDispatchOnce(^{
        cache = [[PWLocalizerCache alloc] init];
    });
    return cache;
}

- (PWLocalizer*)localizerForClass:(Class)aClass
                         language:(NSString*)language
                    creationBlock:(PWLocalizerCreationBlock)creationBlock
{
    __block PWLocalizer* result;
    [_dispatchQueue synchronouslyDispatchBlock:^{
        CacheKey key = {aClass, language};
        __strong PWLocalizer*& localizer = _cache[key];
        if(!localizer)
            localizer = creationBlock(aClass, language);
        result = localizer;
    }];
    return result;
}

@end
