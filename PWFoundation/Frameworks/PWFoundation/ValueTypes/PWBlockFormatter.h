//
//  PWBlockFormatter.h
//  PWFoundation
//
//  Created by Frank Illenberger on 10.03.10.
//
//

@interface PWBlockFormatter : NSFormatter

@property (nonatomic, readwrite, copy)     NSString* (^toStringBlock)     (PWBlockFormatter* formatter, id objectValue);

@property (nonatomic, readwrite, copy)     BOOL      (^toObjectValueBlock)(PWBlockFormatter* formatter, id* objectValue, NSString* string, NSString** errorDesc);

// Simple storage properties that can be used by custom implementations of -[PWValueType configureFormatter:forObject:keyPath:]
// to store the object and keyPath parameters.
@property (nonatomic, readwrite, strong)   id        preparationObject;
@property (nonatomic, readwrite, copy)     NSString* preparationKeyPath;

- (id)objectForString:(NSString*)string;    // convenience method

@end



