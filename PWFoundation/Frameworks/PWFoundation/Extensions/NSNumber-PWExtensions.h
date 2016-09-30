//
//  NSNumber-PWExtensions.h
//  PWFoundation
//
//  Created by Andreas Känner on 28.05.09.
//
//

#import <PWFoundation/PWTypes.h>
#import <PWFoundation/PWComparing.h>

@interface NSNumber (PWExtensions) <PWComparing>

- (instancetype)initWithStringRepresentation:(NSString*)string error:(NSError**)outError;

// makes sure the returned number is of objType bool
@property (nonatomic, readonly, copy) NSNumber *numberAsBool;

// conveniences to avoid neccessary typecasts on GCC_WARN_64_TO_32_BIT_CONVERSION
@property (nonatomic, readonly) PWInteger pwintegerValue;
@property (nonatomic, readonly) PWUInteger pwunsignedIntegerValue;

@end
