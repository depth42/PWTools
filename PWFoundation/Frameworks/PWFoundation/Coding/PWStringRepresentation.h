//
//  PWStringRepresentation.h
//  PWFoundation
//
//  Created by Andreas Känner on 27.05.09.
//
//

@protocol PWStringRepresentation

- (instancetype)initWithStringRepresentation:(NSString*)stringRepresentation error:(NSError**)outError;

@optional
@property (nonatomic, readonly, copy) NSString *stringRepresentation;

@end
