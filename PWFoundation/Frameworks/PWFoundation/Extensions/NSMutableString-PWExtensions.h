//
//  NSMutableString-PWExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 05.12.05.
//
//

@interface NSMutableString (PWExtensions)

- (void)appendInteger:(NSInteger)val base:(NSUInteger)base;
- (void)appendIntegerUppercase:(NSInteger)val base:(NSUInteger)base;
- (void)removeInvalidXMLCharacters;

@end
