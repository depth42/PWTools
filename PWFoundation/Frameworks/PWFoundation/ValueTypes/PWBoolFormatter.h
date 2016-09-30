//
//  PWBoolFormatter.h
//  PWFoundation
//
//  Created by Frank Illenberger on 02.03.10.
//
//

#import <Foundation/Foundation.h>

@class PWLocality;

@interface PWBoolFormatter : NSFormatter

@property (nonatomic, readwrite, strong) PWLocality* locality;
@property (nonatomic, readwrite)         BOOL        allowsMixed;
@property (nonatomic, readwrite)         BOOL        showsYesAndNo;

@end
