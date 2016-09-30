//
//  PWValueTypeTestObject.h
//  PWFoundation
//
//  Created by Frank Illenberger on 09.11.10.
//
//

#import <Foundation/Foundation.h>


@interface PWValueTypeTestObject : NSObject 

@property (nonatomic, copy) NSNumber* value;
@property (nonatomic, copy) NSNumber* fallbackValue;

@end
