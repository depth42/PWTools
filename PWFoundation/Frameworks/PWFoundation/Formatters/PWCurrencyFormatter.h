//
//  PWCurrencyFormatter.h
//  PWFoundation
//
//  Created by Frank Illenberger on 04.03.10.
//
//

#import <Foundation/Foundation.h>

@class PWLocality;

@interface PWCurrencyFormatter : NSNumberFormatter

@property (nonatomic, readonly, strong) PWLocality* locality;
@property (nonatomic, readonly)         BOOL        hideZeroes;

- (instancetype)initWithLocality:(PWLocality*)locality
            hideZeroes:(BOOL)hideZeroes;

@end
