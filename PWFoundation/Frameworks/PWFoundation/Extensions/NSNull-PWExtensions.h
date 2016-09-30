//
//  NSNull-PWExtensions.h
//  PWFoundation
//
//  Created by Kai Brüning on 25.3.11.
//
//

/*
 This extension overwrites PWEnumerable methods to enumerate nothing and supports xml coding.
 
 A NSNull is represented by <null/> in xml. Note that xsi:nil is meant for nil values and not suited to represent a null
 element. We are not aware of any standard for representing a null element.
 
 Note: currently (10.3.2014) xml coding of NSNulls is not used anywhere in Merlin.
 */

@interface NSNull (PWExtensions)

@end

NS_INLINE id PWNullForNil (id object) { return object ? object : [NSNull null]; }

NS_INLINE id PWNilForNull (id object) { return (object == [NSNull null]) ? nil : object; }
