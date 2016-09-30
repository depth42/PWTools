//
//  NSFormatter-PWExtensions.h
//  PWFoundation
//
//  Created by Kai Brüning on 1.7.10.
//
//

#import <Foundation/Foundation.h>

@interface NSFormatter (PWExtensions)

// Sets a value which can be used by -getObjectValue:forString:errorDescription: to augment the information in the
// string. Typically 'obj' is an old value which is used to e.g. copy a unit if the new string does not contain one.
// NSFormatter (PWExtensions) ignores the value.
- (void) setReferenceObjectValue:(id)obj;

- (BOOL)getObjectValue:(id*)anObject forString:(NSString*)string error:(NSError**)outError;

@end
