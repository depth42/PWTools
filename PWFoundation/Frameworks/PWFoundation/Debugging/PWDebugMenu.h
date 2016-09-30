//
//  PWDebugMenu.h
//  PWAppKit
//
//  Created by Kai Brüning on 26.1.10.
//
//

#import "PWDebugOptions.h"
#import "PWDebugOptionGroup.h"

#if UXTARGET_IOS

#import "PWDebugMenu-iOS.h"

#else

#import <AppKit/AppKit.h>

extern NSString* const PWDebugMenuEnabledKey;

@interface PWDebugOptionGroup (PWDebugMenu)

@property (nonatomic, readonly, copy) NSMenu *createMenu;

@end


@interface PWRootDebugOptionGroup (PWDebugMenu)

// Always YES if NDEBUG is not defined, else the state of the user default value under PWDebugOptionsEnabledKey.
// Setter sets user default value, independent of NDEBUG state.
+ (BOOL) isDebugMenuEnabled;
+ (void) setIsDebugMenuEnabled:(BOOL)value;

// Note: this method sets isDebugMenuEnabled to YES if NDEBUG is not defined. This enables the debug menu if the
// release version is later run on the same machine.
- (void) insertDebugMenuInMainMenu:(NSMenu*)mainMenu beforeItemWithTag:(NSInteger)aTag;

- (void) createDebugMenuInMenuItem:(NSMenuItem*)debugMenuItem;

@end


@interface PWDebugOption (PWDebugMenu)

@property (nonatomic, readonly)         NSInteger   orderInMenu;    // default is 0, -100 for sub menus

@property (nonatomic, readonly, copy)   NSString*   menuItemTitle;  // default is self.title

- (void) addMenuItemToMenu:(NSMenu*)aMenu;

// Create a basic menu item for this debug item. For use by sub classes.
- (NSMenuItem*) createMenuItemWithAction:(SEL)aSelector;

@end

#endif
