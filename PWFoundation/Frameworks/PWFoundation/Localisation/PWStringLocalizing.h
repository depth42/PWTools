/*
 *  PWStringLocalizing.h
 *  PWFoundation
 *
 *  Created by Kai Brüning on 25.3.10.
 *  Copyright 2010 ProjectWizards. All rights reserved.
 *
 */

@protocol PWStringLocalizing

// 'fallback' is used if 'key' is not found in localization tables.
- (NSString*) localizedStringForKey:(NSString*)key value:(NSString*)fallback;

// Convenience method, equivalent to sending -localizedStringForKey:value: passing 'string' for both parameters.
- (NSString*) localizedString:(NSString*)string;

@end
