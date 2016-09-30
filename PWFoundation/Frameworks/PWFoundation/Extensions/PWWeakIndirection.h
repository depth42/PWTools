//
//  PWWeakIndirection.h
//  PWFoundation
//
//  Created by Kai Brüning on 26.6.13.
//
//

#import <Foundation/Foundation.h>

@interface PWWeakIndirection : NSObject

- (instancetype) initWithIndirectedObject:(id)indirectedObject;

@property (nonatomic, readonly, weak)   id  pw_indirectedObject;

@end

#pragma mark

@interface NSObject (PWWeakIndirection)

@property (nonatomic, readonly, strong) id pw_indirectedObject;   // returns self

@end
