//
//  PWEnumFormatter.h
//  PWFoundation
//
//  Created by Frank Illenberger on 03.03.10.
//
//

@class PWLocality;
@class PWLocalizer;

@interface PWEnumFormatter : NSFormatter

// Designated initializer
- (instancetype) initWithLocalizer:(PWLocalizer*)localizer
                  values:(NSArray*)theValues      // hashable, copyable,
        unlocalizedNames:(NSArray*)names         // NSString, same count as values
 unlocalizedNilValueName:(NSString*)unlocalizedNilName
   localizationKeyPrefix:(NSString*)localizationKeyPrefix;

- (instancetype) initWithLocality:(PWLocality*)aLocality
                 bundle:(NSBundle*)aBundle
                 values:(NSArray*)theValues      // hashable, copyable, 
       unlocalizedNames:(NSArray*)names         // NSString, same count as values
unlocalizedNilValueName:(NSString*)unlocalizedNilName
  localizationKeyPrefix:(NSString*)localizationKeyPrefix;

@property (nonatomic, readwrite)        BOOL        capitalizesFirstCharacter;

@property (nonatomic, readonly, strong) PWLocalizer*    localizer;
@property (nonatomic, readonly, copy)   NSArray*        values;
@property (nonatomic, readonly, copy)   NSArray*        unlocalizedNames;
@property (nonatomic, readonly, copy)   NSString*       unlocalizedNilValueName;
@property (nonatomic, readonly, copy)   NSString*       localizationKeyPrefix;

@end
