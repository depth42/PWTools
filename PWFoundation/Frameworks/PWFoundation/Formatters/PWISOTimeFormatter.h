//
//  PWISOTimeFormatter.h
//  PWFoundation
//
//  Created by Frank Illenberger on 23.09.10.
//
//

@interface PWISOTimeFormatter : NSFormatter
- (NSNumber*)timeFromString:(NSString*)string;      // PWTimeOfDay
- (NSString*)stringFromTime:(NSNumber*)time;        // PWTimeOfDay
@end
