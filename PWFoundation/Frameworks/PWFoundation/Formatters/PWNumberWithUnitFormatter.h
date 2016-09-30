//
//  PWNumberWithUnitFormatter.h
//  PWFoundation
//
//  Created by Torsten Radtke on 24.03.11.
//
//

@interface PWNumberWithUnitFormatter : NSNumberFormatter

#pragma mark Setting unit and factor

- (void)setUnit:(NSString*)unit factor:(double)factor;

@property (nonatomic, readonly, copy)   NSString* unit;
@property (nonatomic, readonly)         double    factor;

@end
