//
//  PWLeakChecker.h
//  PWFoundation
//
//  Created by Frank Illenberger on 09/07/15.
//
//

#ifndef NDEBUG

@interface PWLeakChecker : NSObject

+ (PWLeakChecker*)sharedLeakChecker;

- (void) addLivingInstance:(id)instance;
- (void) removeLivingInstance:(__unsafe_unretained id)instance;
- (void) resetLivingInstances;
- (void) dumpLivingInstances;   // note: destructive, that is dumping includes the effect of -resetLivingInstances

// Safe and non-destructive dump of the current list of living instances for debugging purposes.
- (void) dumpLivingInstanceClassesAndPointers;

// Gracefully lets the run loop run for a while to give the still living objects a chance to get deallocated.
// If after a timeout this has not succeeded, NO is returned. Otherwise YES.
@property (nonatomic, readonly) BOOL checkLivingInstances;

- (NSArray*)livingInstancesOfClass:(Class)aClass;

// Expected survivors are excluded from leak checking
- (void) addExpectedSurvivor:(id)instance;
- (void) removeExpectedSurvivor:(__unsafe_unretained id)instance;
- (BOOL) isExpectedSurvivor:(__unsafe_unretained id)instance;


@end

#pragma mark

@interface NSObject (PWLeakChecker)

// Gets called from -[PWLeakChecker isExpectedSurvivor:] and performs the test. Can be overridden by subclasses to additionally
// forward to other survivor checks. For example a managed object is considered to be an expected survivor if its context
// is an expected survivor. Should not be called directly.
// Is called on a single private dispatch queue.
// IMPORTANT: the receiver must NOT be retained temporarily by this method or any of its callees, because the message
// can be send to objects which already have a retain count of 0 but are not yet deallocated (by Core Data for managed
// objects).
- (BOOL) isExpectedSurvivorInLeakChecker:(PWLeakChecker*)checker;

@end

#endif
