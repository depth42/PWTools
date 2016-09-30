//
//  NSDate-PWTestExtensions.h
//  MerlinModel
//
//  Created by Kai on 11.3.10.
//
//

#import <Foundation/Foundation.h>


@interface NSDate (PWTestExtensions)

// Creates dates from strings of the form y-M-d or y-M-d'T'H:m:S.
+ (NSDate*) dateWithISOString:(NSString*)dateString;
+ (NSDate*) dateWithISOString:(NSString*)dateString timeZone:(NSTimeZone*)timeZone;
+ (NSDate*) GMTDateWithISOString:(NSString*)dateString;

@end
