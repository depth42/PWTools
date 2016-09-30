/*
 *  PWMutability.h
 *  PWFoundation
 *
 *  Created by Frank Illenberger on 21.11.2011.
 *  Copyright 2011 ProjectWizards. All rights reserved.
 *
 */

// Protocol for objects which are created mutable and which can later give up their mutability.
@protocol PWMutability <NSMutableCopying, NSCopying>
- (void)makeImmutable;
@property (nonatomic, readonly) BOOL isImmutable;
@end