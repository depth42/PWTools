//
//  PWLocalizer.h
//  Merlin
//
//  Created by Andreas Känner on 13.09.2011.
//
//


#import <PWFoundation/PWStringLocalizing.h>
#import <PWFoundation/PWDebugOptionMacros.h>


@interface PWLocalizer : NSObject < PWStringLocalizing >

@property (nonatomic, readonly, copy)   NSArray*    tables;
@property (nonatomic, readonly, strong) NSBundle*   bundle;
@property (nonatomic, readonly, copy)   NSArray*    subLocalizers;
@property (nonatomic, readonly, copy)   NSString*   language;


+ (PWLocalizer*)localizerWithTables:(NSArray*)tables bundle:(NSBundle*)bundle language:(NSString*)language;
+ (PWLocalizer*)localizerWithSubLocalizers:(NSArray*)subLocalizers;         // uniqued

- (void)localizeObjects:(NSArray*)objects;

// Methods from PWStringLocalizing
- (NSString*)localizedStringForKey:(NSString*)key value:(NSString*)fallback;
- (NSString*)localizedString:(NSString*)string;

@end

@protocol PWLocalizableObject
- (void)localizeWithLocalizer:(PWLocalizer*)localizer;
@end

