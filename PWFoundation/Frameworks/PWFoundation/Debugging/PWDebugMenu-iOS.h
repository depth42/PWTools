//
//  PWDebugMenu-iOS.h
//  PWAppKit
//
//  Created by Berbie on 15.08.16.
//
//

#import <PWFoundation/PWDebugOptionGroup.h>

NS_ASSUME_NONNULL_BEGIN

/**
 A singleton instance of PWDebugMenuController typically lives in a property on the MainController. 
 From there, any viewController may pull up the debug menu by calling presentDebugMenu. 
 Available debug menu options are declated in code, see <PWFoundation/PWDebugOptionMacros.h>
 */
@interface PWDebugMenuController : NSObject

- (void)presentDebugMenu;

@end

@interface PWRootDebugOptionGroup (PWDebugMenu)

// Always YES if NDEBUG is not defined, else the state of the user default value under PWDebugOptionsEnabledKey.
// Setter sets user default value, independent of NDEBUG state.
+ (BOOL) isDebugMenuEnabled;
+ (void) setIsDebugMenuEnabled:(BOOL)value;

@end

NS_ASSUME_NONNULL_END
