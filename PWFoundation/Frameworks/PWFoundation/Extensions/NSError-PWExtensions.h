//
//  NSError-PWExtensions.h
//  PWFoundation
//
//  Created by Frank Illenberger on 27.03.09.
//
//

NS_ASSUME_NONNULL_BEGIN

@protocol PWStringLocalizing;

// The object affected by the error can be stored under this key in user info.
extern NSString* const PWAffectedObjectErrorKey;
extern NSString* const PWErrorOriginErrorKey;
extern NSString* const PWErrorContextErrorKey;

// Optional block which can be added to an error to provide error recovery.
// When a nextError is provided, the presentation will be continued with the nextError.
// This enables multiple chained error recovery alerts.
// Note: This is currently only implemented in the higher layers for error presentation on the Mac in PWApplication (not in iOS or Weblitz)
typedef BOOL (^PWErrorRecoveryBlock) (NSError* error, NSUInteger optionIndex, NSError* _Nullable * _Nullable outNextError);

typedef void (^PWErrorRecoveryAttemptCompletionHandler)(BOOL didRecover, NSError* _Nullable nextError);

// Convenience typedef for the frequent case of a completion handler which gets passed on optional error to indicate
// failure.
typedef void (^PWCompletionHandlerWithError) (NSError* _Nullable error);

#define PWErrorOrigin                  [NSString stringWithFormat:@"%s:%d",__FILE__, __LINE__]

/**
 May be used to trace code locations of errors created by system calls like:
 if(![fileMmanager removeItemAtURL:fileURL error:outError]) return PWErrorRefEnsureOrigin(outError, context, NO);
 Comma operator is used to return the given retVal.
 */
#define PWErrorRefEnsureOrigin(errRef,errCtx,retVal)  ((void)[NSError ensureErrorOrigin:errRef origin:PWErrorOrigin context:errCtx], (retVal))

/**
 replacement for [NSError ensureError:] that appends an origin and optional context
 */
#define PWEnsureError(err,errCtx) [NSError ensureError:err origin:PWErrorOrigin context:errCtx]

// Regarding PWXMLCoding compliance: Values inside the user info dictionary are only XML encoded if they are also PWXMLCoding compliant.
@interface NSError (PWExtensions)

// Removes unencodable stuff from the error's userInfo dict
@property (nonatomic, readonly, copy) NSError * _Nonnull encodableError;

// Convenience method to create an error with a localized description in its userInfo.
// 'localizationContext' can be nil (for no localization).
// 'format' must be a valid string.
+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                      format:(NSString*)format, ... NS_FORMAT_FUNCTION(4,5);

// Same as above without 'localizationContext', that is for unlocalized errors.
+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
                      format:(NSString*)format, ... NS_FORMAT_FUNCTION(3,4);

// Same as above with affectedObject.
+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
              affectedObject:(nullable id)affectedObject
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                      format:(NSString*)format, ... NS_FORMAT_FUNCTION(5,6);

+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
              affectedObject:(nullable id)affectedObject
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                      format:(NSString*)format
                   arguments:(va_list)argList NS_FORMAT_FUNCTION(5,0);

// Convenience method to create an error with a localized description, failureReason and/or recoverySuggestion in its
// userInfo.
// 'localizationContext' can be nil (for no localization).
// Any of the strings can be nil.
+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                 description:(nullable NSString*)description
               failureReason:(nullable NSString*)failureReason
          recoverySuggestion:(nullable NSString*)recoverySuggestion;

// Same as above with affectedObject.
+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
              affectedObject:(nullable id)affectedObject
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                 description:(nullable NSString*)description
               failureReason:(nullable NSString*)failureReason
          recoverySuggestion:(nullable NSString*)recoverySuggestion;

// Block-based interface for the error recovery mechanism.
// 'localizationContext' can be nil (for no localization).
+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                     message:(NSString*)message
          recoverySuggestion:(nullable NSString*)recoverySuggestion
                     options:(nullable NSArray*)options
                       block:(nullable PWErrorRecoveryBlock)block;

// Same as above with affectedObject and nextError
+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
              affectedObject:(nullable id)affectedObject
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                     message:(NSString*)message
          recoverySuggestion:(nullable NSString*)recoverySuggestion
                     options:(nullable NSArray*)options
             underlyingError:(nullable NSError*)underlyingError
                       block:(nullable PWErrorRecoveryBlock)recoveryBlock;

// Deprecated variant without localization context.
+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
                     message:(NSString*)message
          recoverySuggestion:(nullable NSString*)recoverySuggestion
                     options:(nullable NSArray*)options
                       block:(nullable PWErrorRecoveryBlock)block;

// Tries to trigger the asynchronous method in the recovery attempter of the receiver. If it is not implemented it falls
// back to the synchronous method.
// If the receiver does not have a recovery attempter, the completion hanlder is called with didRecover=NO
- (void) attemptRecoveryWithOptionIndex:(NSUInteger)optionsIndex
                      completionHandler:(nullable PWErrorRecoveryAttemptCompletionHandler)completionHandler;

// Trigger the synchronous method in the recovery attempter.
- (BOOL) attemptRecoveryWithOptionIndex:(NSUInteger)optionIndex
                              nextError:(NSError**)outNextError;

// Returns 'error' if non-nil and returns an error with PWErrorDomain/PWGenericError else.
// To be used if an API requests a non-nil error to signature failure and another did not provide one.
+ (NSError*) ensureError:(nullable NSError*)error;

/** if given errors count is zero, returns, generic error, if one: returns that, if more retuens generic error with PWUnderlyingErrorsKey
 parameter origin expects result of macro PWErrorOrigin */
+ (NSError*)ensureErrorWithErrors:(NSArray<NSError*>*)errors origin:(NSString*)origin;

// same as ensureError: but extends origin and context scheme
+ (NSError*)ensureError:(nullable NSError*)in_error origin:(NSString*)origin context:(nullable id)context;

/** Static helper for PWErrorRefEnsureOrigin. Rewrites given error to contain a file:line origin. */
+ (BOOL)ensureErrorOrigin:(inout NSError* _Nullable*_Nullable)inoutError origin:(NSString*)origin context:(nullable id)context;

+ (NSError*) userCancelledErrorWithFormat:(NSString*)format, ... NS_FORMAT_FUNCTION(1,2);

@property (nonatomic, readonly, copy,   nullable)   NSString*               message;
@property (nonatomic, readonly, copy,   nullable)   NSString*               recoverySuggestion;
@property (nonatomic, readonly, copy,   nullable)   NSString*               failureReason;
@property (nonatomic, readonly, copy,   nullable)   NSString*               userPresentableDescription;  // Joins message, recoverySuggestion and failure reason.
@property (nonatomic, readonly, strong, nullable)   id                      affectedObject;             // PWAffectedObjectErrorKey in user info
@property (nonatomic, readonly, copy,   nullable)   NSArray<NSString*>*     recoveryOptions;
@property (nonatomic, readonly, copy,   nullable)   PWErrorRecoveryBlock    recoveryBlock;

// Returns the recovery option index that was chosen when a recovery attempt was performed last.
// Returns nil, if no recovery was ever attempted.
@property (nonatomic, readonly, copy,   nullable)   NSNumber*               lastChosenRecoveryOptionIndex;

@property (nonatomic, readonly)                     BOOL                    isInCocoaDomain;
@property (nonatomic, readonly)                     BOOL                    isUserCancelledError;
@property (nonatomic, readonly)                     BOOL                    isNoSuchFileError;

@property (nonatomic, readonly)                     BOOL                    isInPWDomain;

@end

NS_ASSUME_NONNULL_END
