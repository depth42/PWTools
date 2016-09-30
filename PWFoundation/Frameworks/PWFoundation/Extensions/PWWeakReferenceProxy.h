//
//  PWWeakReferenceProxy.h
//  PWFoundation
//
//  Created by Kai Brüning on 9.11.11.
//
//

#import <Foundation/Foundation.h>
#import "NSObject-PWExtensions.h"

/*
 This class is used to make objects weak-referencable which aren’t directly. This complete list of classes which do
 not support weak-referencing (as of 10.8) is:
    NSATSTypesetter, NSColorSpace, NSFont, NSFontManager, NSFontPanel, NSImage, NSMenuView, NSParagraphStyle,
    NSSimpleHorizontalTypesetter, NSTableCellView, NSTextView, NSConnection, NSMachPort, and NSMessagePort.
 
 To make one of these classes weak-referencable using the proxy, a sub class is needed. This sub class implements
 the property weakReferencableObject (introduced in NSObject (PWExtensions) to return self) to return an instance of
 PWWeakReferenceProxy, which is hold strongly by the sub class. In its dealloc method the sub class sends -dispose
 to the proxy, thereby breaking the connection to itself. The need to use dealloc is the reason a sub class is necessary
 (unless method swivelling is employed).
*/

@interface PWWeakReferenceProxy : NSObject

@property (nonatomic, readonly, assign) id  weakReferencedObject;

- (instancetype) initWithProxiedObject:(id)proxiedObject;

- (void) dispose;

@end
