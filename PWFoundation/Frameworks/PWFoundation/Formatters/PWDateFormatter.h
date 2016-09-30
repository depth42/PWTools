//
//  PWDateFormatter.h
//  PWFoundation
//
//  Created by Kai Brüning on 17.11.10.
//
//

#import <Foundation/Foundation.h>

/*
 Adds the ability to turn empty strings into nil objects.

 In addition if isLenient is set to YES, the formatter tries to convert object values from strings 
 by using different date and time styles to parse the string until a date can be extracted or all supported style
 combinations are used.
 
 */

@interface PWDateFormatter : NSDateFormatter

@property (nonatomic, readwrite)    BOOL    allowsEmpty;

@end
