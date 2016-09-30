//
//  NSError-PWExtensions.m
//  PWFoundation
//
//  Created by Frank Illenberger on 27.03.09.
//
//

#import "NSError-PWExtensions.h"
#import "PWStringLocalizing.h"
#import "NSArray-PWExtensions.h"
#import "NSObject-PWExtensions.h"
#import "NSDictionary-PWExtensions.h"
#import "PWErrors.h"
#import "NSPropertyListSerialization-PWExtensions.h"

NS_ASSUME_NONNULL_BEGIN

NSString* const PWAffectedObjectErrorKey    = @"net.projectwizards.NSError.affectedObject";
static NSString* const RecoveryBlockKey     = @"net.projectwizards.NSError.recoveryBlock";
NSString* const PWErrorOriginErrorKey       = @"net.projectwizards.NSError.origin";
NSString* const PWErrorContextErrorKey      = @"net.projectwizards.NSError.context";


@implementation NSError (PWExtensions)

- (NSError*)encodableError
{
    NSDictionary *info = @{NSLocalizedDescriptionKey: self.localizedDescription};
    return [NSError errorWithDomain:self.domain code:self.code userInfo:info];
}

- (nullable NSString*)message
{
    return (self.userInfo)[NSLocalizedDescriptionKey];
}

- (nullable NSString*)recoverySuggestion
{
    return (self.userInfo)[NSLocalizedRecoverySuggestionErrorKey];
}

- (nullable NSArray*)recoveryOptions
{
    return (self.userInfo)[NSLocalizedRecoveryOptionsErrorKey];
}

- (nullable NSString*)failureReason
{
    return (self.userInfo)[NSLocalizedFailureReasonErrorKey];
}

- (nullable NSString*)userPresentableDescription
{
    NSMutableArray* components = [NSMutableArray array];
    
    NSString* message = self.message;
    if(message)
        [components addObject:message];
    NSString* recoverySuggestion = self.recoverySuggestion;
    if(recoverySuggestion)
        [components addObject:recoverySuggestion];
    NSString* failureReason = self.failureReason;
    if(failureReason)
        [components addObject:failureReason];
    
    if(components.count == 0)
        return nil;
    
    return [components componentsJoinedByString:@"\n"];
}

- (nullable NSString*)affectedObject
{
    return (self.userInfo)[PWAffectedObjectErrorKey];
}

- (nullable PWErrorRecoveryBlock)recoveryBlock
{
    return (self.userInfo)[RecoveryBlockKey];
}

+ (NSError*)errorWithDomain:(NSString*)domain
                       code:(NSInteger)code
             affectedObject:(nullable id)affectedObject
        localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                    message:(NSString*)message
         recoverySuggestion:(nullable NSString*)recoverySuggestion
                    options:(nullable NSArray*)options
            underlyingError:(nullable NSError*)underlyingError
                      block:(nullable PWErrorRecoveryBlock)block
{
    NSParameterAssert (domain);
    NSParameterAssert (message);

    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    
    if (affectedObject)
        userInfo[PWAffectedObjectErrorKey] = affectedObject;
    
    if (localizationContext)
        message = [localizationContext localizedString:message];
    userInfo[NSLocalizedDescriptionKey] = message;
    
    if (recoverySuggestion) {
        if (localizationContext)
            recoverySuggestion = [localizationContext localizedString:recoverySuggestion];
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion;
    }
    
    if(underlyingError)
        userInfo[NSUnderlyingErrorKey] = underlyingError;
    
    if (block) {
        NSParameterAssert (options);
        
        if (localizationContext)
            options = [options map:^(id arg1) { return [localizationContext localizedString:arg1]; }];
        userInfo[NSLocalizedRecoveryOptionsErrorKey] = options;
        
        userInfo[NSRecoveryAttempterErrorKey] = self;
        userInfo[RecoveryBlockKey] = [block copy];
    }

    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

+ (NSError*)errorWithDomain:(NSString*)domain
                       code:(NSInteger)code
        localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                    message:(NSString*)message
         recoverySuggestion:(nullable NSString*)recoverySuggestion
                    options:(nullable NSArray*)options
                      block:(nullable PWErrorRecoveryBlock)block
{
    NSParameterAssert (domain);
    NSParameterAssert (message);
    
    return [self errorWithDomain:domain
                            code:code
                  affectedObject:nil
             localizationContext:localizationContext
                         message:message
              recoverySuggestion:recoverySuggestion
                         options:options
                 underlyingError:nil
                           block:block];
}

+ (NSError*)errorWithDomain:(NSString*)domain
                       code:(NSInteger)code
                    message:(NSString*)message
         recoverySuggestion:(nullable NSString*)recoverySuggestion
                    options:(nullable NSArray*)options
                      block:(nullable PWErrorRecoveryBlock)block
{
    NSParameterAssert (domain);
    NSParameterAssert (message);
    
    return [self errorWithDomain:domain
                            code:code
                  affectedObject:nil
             localizationContext:nil
                         message:message
              recoverySuggestion:recoverySuggestion
                         options:options
                 underlyingError:nil
                           block:block];
}

- (BOOL) attemptRecoveryWithOptionIndex:(NSUInteger)optionIndex
                              nextError:(NSError**)outNextError
{
    PWErrorRecoveryBlock recoveryBlock = (self.userInfo)[RecoveryBlockKey];
    if(recoveryBlock)
        return recoveryBlock(self, optionIndex, outNextError);

    id recoveryAttempter = self.recoveryAttempter;
    if (!recoveryAttempter)
        return NO;
    
    PWAssert([recoveryAttempter respondsToSelector:@selector(attemptRecoveryFromError:optionIndex:)]);
    return [recoveryAttempter attemptRecoveryFromError:self optionIndex:optionIndex];
}

- (void) attemptRecoveryWithOptionIndex:(NSUInteger)optionsIndex
                      completionHandler:(nullable PWErrorRecoveryAttemptCompletionHandler)completionHandler
{
    PWErrorRecoveryBlock recoveryBlock = (self.userInfo)[RecoveryBlockKey];
    if(recoveryBlock)
    {
        NSError* nextError;
        BOOL didRecover = recoveryBlock(self, optionsIndex, &nextError);
        if(completionHandler)
            completionHandler(didRecover, nextError);
        return;
    }

    id recoveryAttempter = self.recoveryAttempter;
    if (!recoveryAttempter)
    {
        if(completionHandler)
            completionHandler(/* didRecover */ NO, /* nextError */ nil);
        return;
    }

    if([recoveryAttempter respondsToSelector:@selector(attemptRecoveryFromError:optionIndex:delegate:didRecoverSelector:contextInfo:)])
    {
        [recoveryAttempter attemptRecoveryFromError:self
                                        optionIndex:optionsIndex
                                           delegate:self
                                 didRecoverSelector:@selector(didAttemptErrorRecovery:contextInfo:)
                                        contextInfo:(__bridge_retained void*)[completionHandler copy]];
    }
    else
    {
        NSError* nextError;
        BOOL didRecover = [self attemptRecoveryWithOptionIndex:optionsIndex nextError:&nextError];
        if(completionHandler)
            completionHandler(didRecover, nextError);
    }
}

- (void)didAttemptErrorRecovery:(BOOL)didRecover contextInfo:(void*)contextInfo
{
    PWErrorRecoveryAttemptCompletionHandler completionHandler = (__bridge_transfer PWErrorRecoveryAttemptCompletionHandler)contextInfo;
    if(completionHandler)
        completionHandler(didRecover, /* nextError */ nil);
}

#pragma mark - Implementing error recovery attemption informal protocol

+ (BOOL)attemptRecoveryFromError:(NSError*)error optionIndex:(NSUInteger)recoveryOptionIndex
{
    error.lastChosenRecoveryOptionIndex = @(recoveryOptionIndex);
    PWErrorRecoveryBlock block = (error.userInfo)[RecoveryBlockKey];
    NSAssert(block, nil);
    return block(error, recoveryOptionIndex, /* nextError */ NULL);
}

+ (void)attemptRecoveryFromError:(NSError*)error
                     optionIndex:(NSUInteger)recoveryOptionIndex
                        delegate:(id)delegate
              didRecoverSelector:(SEL)didRecoverSelector
                     contextInfo:(void*)contextInfo
{
    error.lastChosenRecoveryOptionIndex = @(recoveryOptionIndex);
    PWErrorRecoveryBlock block = (error.userInfo)[RecoveryBlockKey];
    NSAssert(block, nil);
    BOOL recovered = block(error, recoveryOptionIndex, /* nextError */ NULL);
    if(delegate && didRecoverSelector)
    {
        NSMethodSignature* signature = [delegate methodSignatureForSelector:didRecoverSelector];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.selector = didRecoverSelector;
        invocation.target = delegate;
        [invocation setArgument:&recovered atIndex:2];
        [invocation setArgument:&contextInfo atIndex:3];
        [invocation invoke];
    }
}

#pragma mark - Convenience methods

+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                      format:(NSString*)format, ...
{
    NSParameterAssert (format);
    
    va_list argList;
    va_start (argList, format);
    
    NSError* error = [self errorWithDomain:domain
                                      code:code
                            affectedObject:nil
                       localizationContext:localizationContext
                                    format:format
                                 arguments:argList];
    
    va_end (argList);
    
    return error;
}

+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
                      format:(NSString*)format, ...
{
    NSParameterAssert (format);
    
    va_list argList;
    va_start (argList, format);
    
    NSError* error = [self errorWithDomain:domain
                                      code:code
                            affectedObject:nil
                       localizationContext:nil
                                    format:format
                                 arguments:argList];
    
    va_end (argList);
    
    return error;
}

+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
              affectedObject:(nullable id)affectedObject
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                      format:(NSString*)format, ...
{
    NSParameterAssert (format);
    
    va_list argList;
    va_start (argList, format);
    
    NSError* error = [self errorWithDomain:domain
                                      code:code
                            affectedObject:affectedObject
                       localizationContext:localizationContext
                                    format:format
                                 arguments:argList];
    
    va_end (argList);
    
    return error;
}

+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
              affectedObject:(nullable id)affectedObject
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                      format:(NSString*)format
                   arguments:(va_list)argList
{
    NSParameterAssert (format);
    
    if (localizationContext)
        format = [localizationContext localizedString:format];
    NSString* errorMessage = [[NSString alloc] initWithFormat:format arguments:argList];
    NSDictionary* userInfo;
    if(affectedObject)
        userInfo = @{NSLocalizedDescriptionKey: errorMessage, PWAffectedObjectErrorKey: affectedObject};
    else
        userInfo = @{NSLocalizedDescriptionKey: errorMessage};
    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                 description:(nullable NSString*)description
               failureReason:(nullable NSString*)failureReason
          recoverySuggestion:(nullable NSString*)recoverySuggestion
{
    return [self errorWithDomain:domain
                            code:code
                  affectedObject:nil
             localizationContext:localizationContext
                     description:description
                   failureReason:failureReason
              recoverySuggestion:recoverySuggestion];
}

+ (NSError*) errorWithDomain:(NSString*)domain
                        code:(NSInteger)code
              affectedObject:(nullable id)affectedObject
         localizationContext:(nullable id<PWStringLocalizing>)localizationContext
                 description:(nullable NSString*)description
               failureReason:(nullable NSString*)failureReason
          recoverySuggestion:(nullable NSString*)recoverySuggestion
{
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    
    if (affectedObject)
        userInfo[PWAffectedObjectErrorKey] = affectedObject;
    
    if (description) {
        if (localizationContext)
            description = [localizationContext localizedString:description];
        userInfo[NSLocalizedDescriptionKey] = description;
    }
    
    if (failureReason) {
        if (localizationContext)
            failureReason = [localizationContext localizedString:failureReason];
        userInfo[NSLocalizedFailureReasonErrorKey] = failureReason;
    }
    
    if (recoverySuggestion) {
        if (localizationContext)
            recoverySuggestion = [localizationContext localizedString:recoverySuggestion];
        userInfo[NSLocalizedRecoverySuggestionErrorKey] = recoverySuggestion;
    }
    
    return [NSError errorWithDomain:domain code:code userInfo:userInfo];
}

static NSString* LastChosenRecoveryOptionIndexKey = @"net.projectwizards.lastChosenRecoveryOptionIndex";

- (nullable NSNumber*)lastChosenRecoveryOptionIndex
{
    return [self associatedObjectForKey:LastChosenRecoveryOptionIndexKey];
}

- (void)setLastChosenRecoveryOptionIndex:(nullable NSNumber*)index
{
    [self setAssociatedObject:index forKey:LastChosenRecoveryOptionIndexKey associationPolicy:PWAssociateObjectCopy];
}

+ (NSError*) ensureError:(nullable NSError*)error
{
    return error ? error
    : [NSError errorWithDomain:PWErrorDomain
                          code:PWGenericError
           localizationContext:nil
                        format:@"The operation failed"];
}

+ (NSError*)ensureErrorWithErrors:(NSArray<NSError*>*)errors origin:(NSString*)origin
{
    PWParameterAssert(origin);
    
    NSError* result = errors.lastObject;
    if (errors.count == 0)
    {
        NSDictionary* userInfo = @{ NSLocalizedDescriptionKey       : @"The operation failed",
                                    PWErrorOriginErrorKey           : origin.lastPathComponent };
        result = [NSError errorWithDomain:PWErrorDomain code:PWGenericError userInfo:userInfo];
    }
    else if (errors.count > 1)
    {
        NSDictionary* userInfo = @{ PWUnderlyingErrorsKey           : errors,
                                    NSLocalizedDescriptionKey       : @"The operation failed with multiple errors",
                                    PWErrorOriginErrorKey           : origin.lastPathComponent };
        result = [NSError errorWithDomain:PWErrorDomain code:PWGenericError userInfo:userInfo];
    }
    return result;
}

+ (NSError*)ensureError:(nullable NSError*)in_error origin:(NSString*)origin context:(nullable id)context
{
    NSError* error = [self ensureError:in_error];
    [self ensureErrorOrigin:&error origin:origin context:context];
    return error;
}

+ (BOOL)ensureErrorOrigin:(inout NSError* _Nullable*_Nullable)inoutError origin:(NSString*)origin context:(nullable id)context
{
    PWParameterAssert(origin);
    
    NSError* error;
    if (inoutError)
    {
        error = *inoutError;
        if (error && error.userInfo[PWErrorOriginErrorKey] == nil)
        {
            NSMutableDictionary* info = [error.userInfo mutableCopy];
            info[PWErrorOriginErrorKey] = origin.lastPathComponent;
            if (context) info[PWErrorContextErrorKey] = [NSString stringWithFormat:@"%@", context];
            *inoutError = [NSError errorWithDomain:error.domain code:error.code userInfo:info];
        }
    }
    return (error != nil);
}

+ (NSError*) userCancelledErrorWithFormat:(NSString*)format, ...
{
    va_list argList;
    va_start (argList, format);
    
    NSError* error = [NSError errorWithDomain:NSCocoaErrorDomain
                                         code:NSUserCancelledError
                               affectedObject:nil
                          localizationContext:nil
                                       format:format
                                    arguments:argList];
    
    va_end (argList);
    
    return error;
}

#pragma mark - Convenience Accessors

- (BOOL) isInCocoaDomain
{
    return [self.domain isEqualToString:NSCocoaErrorDomain];
}

- (BOOL) isUserCancelledError
{
    return self.isInCocoaDomain && self.code == NSUserCancelledError;
}

- (BOOL) isNoSuchFileError
{
    return self.isInCocoaDomain && (self.code == NSFileNoSuchFileError || self.code == NSFileReadNoSuchFileError);
}

- (BOOL) isInPWDomain
{
    return [self.domain isEqualToString:PWErrorDomain];
}

@end

NS_ASSUME_NONNULL_END
