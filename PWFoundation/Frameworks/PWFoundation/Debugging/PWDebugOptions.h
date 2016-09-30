//
//  PWDebugOptions.h
//  PWFoundation
//
//  Created by Kai Brüning on 26.1.10.
//
//

#import <Foundation/Foundation.h>

@class PWDebugOptionGroup;

typedef void (^PWDebugActionBlock) (void);


#pragma mark -

@interface PWDebugOption : NSObject

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip;

@property (nonatomic, readonly, copy)  NSString*   title;
@property (nonatomic, readonly, copy)  NSString*   toolTip;

@end

#pragma mark -

@interface PWDebugOptionSubGroup : PWDebugOption
{
@private
    PWDebugOptionGroup* subGroup_;
}

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
            subGroup:(Class)subGroupClass;

@property (nonatomic, readonly)    PWDebugOptionGroup* subGroup;

@end

#pragma mark -

@interface PWDebugSwitchOption : PWDebugOption
{
@private
    _Atomic (BOOL)* target_;
    NSString*       defaultsKey_;
}

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
       booleanTarget:(_Atomic (BOOL)*)target defaultValue:(BOOL)value
   defaultsKeySuffix:(NSString*)keySuffix;

@property (nonatomic, readonly)    _Atomic (BOOL)*  target;
@property (nonatomic, readonly)    NSString*        defaultsKey;

@property (nonatomic, readwrite)   BOOL             currentValue;

// Save current value in user defaults
- (void) saveState;

@end

#pragma mark -

@interface PWDebugEnumOption : PWDebugOption
{
@private
    _Atomic (NSInteger)*    target_;
    NSString*               defaultsKey_;
    NSArray*                values_;
    NSArray*                titles_;
    BOOL                    asSubMenu_;
}

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
           asSubMenu:(BOOL)flag
              target:(_Atomic (NSInteger)*)target
        defaultValue:(NSInteger)value
   defaultsKeySuffix:(NSString*)keySuffix
     titlesAndValues:(NSString*)firstTitle, ... NS_REQUIRES_NIL_TERMINATION;

@property (nonatomic, readonly)    BOOL                 asSubMenu;
@property (nonatomic, readonly)    _Atomic (NSInteger)* target;
@property (nonatomic, readonly)    NSString*            defaultsKey;
@property (nonatomic, readonly)    NSArray*             values;
@property (nonatomic, readonly)    NSArray*             titles;

@property (nonatomic, readwrite)   NSInteger            currentValue;

// Save current value in user defaults
- (void) saveState;

@end

#pragma mark -

@interface PWDebugTextOption : PWDebugOption

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
        stringTarget:(__strong NSString* *)target
   defaultsKeySuffix:(NSString*)keySuffix;

@property (nonatomic, readonly)             __strong NSString* *    target;
@property (nonatomic, readonly, strong)     NSString*               defaultsKey;

@property (nonatomic, readwrite, copy)      NSString*               currentValue;

// Save current value in user defaults
- (void) saveState;

@end

#pragma mark -

@interface PWDebugActionBlockOption : PWDebugOption
{
@private
    PWDebugActionBlock  block_;
}

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
         actionBlock:(PWDebugActionBlock)aBlock;

@property (nonatomic, readonly, copy)    PWDebugActionBlock      block;

- (void) execute:(id)sender;

@end

#pragma mark -

@interface PWDebugActionWithNamedTargetOption : PWDebugOption
{
@private
    NSString*       observableName_;
    NSString*       keyPath_;
    NSString*       selectorName_;
    NSDictionary*   options_;
}

- (instancetype) initWithTitle:(NSString*)title toolTip:(NSString*)toolTip
      observableName:(NSString*)aName
             keyPath:(NSString*)aKeyPath
        selectorName:(NSString*)aSelectorName
             options:(NSDictionary*)aDict;

@property (nonatomic, readonly)    NSString*       observableName;
@property (nonatomic, readonly)    NSString*       keyPath;
@property (nonatomic, readonly)    NSString*       selectorName;
@property (nonatomic, readonly)    NSDictionary*   options;

@end

#pragma mark -

@interface PWDebugNamedObservables : NSObject
@end

