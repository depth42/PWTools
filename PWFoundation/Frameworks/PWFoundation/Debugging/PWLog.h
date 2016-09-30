//
//  PWLog.h
//  PWFoundation
//
//  Created by Kai on 27.11.08.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 PWLog maps to printf of its parameters to stdErr.
 PWLogPush() insets all following PWLogs by one level.
 PWLogPop() undoes the inset of PWLogPush()

 If a value for use_NSLog_for_PWLog exists in user defaults, NSLog is used instead of printf for the final output.
 This helps to see any output from services like the Merlin Server components. For unknown reason printf goes to the
 null device in this case.
 Add "-use_NSLog_for_PWLog 1" to the command line parameters to enable use of NSLog.  
*/

/*!
 The macro HAS_PWLOG controls whether logging via PWLog is enabled. By default, HAS_PWLOG is defined as 1
 if NDEBUG is not defined and as 0 else.
 */

#ifndef HAS_PWLOG
#   ifdef NDEBUG
#       define HAS_PWLOG 0
#   else
#       define HAS_PWLOG 1
#   endif
#endif


#if defined __cplusplus
extern "C" {
#endif

#if HAS_PWLOG

//void pw_log (NSString* format, ...) NS_FORMAT_FUNCTION(1,2);
//void pw_logv (NSString* format, va_list argList) NS_FORMAT_FUNCTION(1,0);
void pw_log_push();
void pw_log_pop();
void pw_log_setBrackets (BOOL bracketInsets);
//void pw_log_addContext (id context);
//void pw_log_removeContext (id context);
NSString* pw_log_inset();

#endif

#if HAS_PWLOG
void PWLog  (NSString* format, ...) NS_FORMAT_FUNCTION(1,2);
void PWLogn (NSString* format, ...) NS_FORMAT_FUNCTION(1,2);
void PWLogv (NSString* format, va_list args) NS_FORMAT_FUNCTION(1,0);
    
// Kai, 10.4.13: As implemented, PWLogAddContext() retained its parameter. This is not good for leak checking.
// Since context-based logging wasn’t used anyway, I disabled it. If we need the feature, we will have to make sure
// that contexts are weakly referenced.
//void PWLogInContext (id context, NSString* format, ...) NS_FORMAT_FUNCTION(2,3);
//BOOL PWWouldLogInContext (id context); 

#else
#define PWLog(format, ...) do{}while(0)
#define PWLogn(format, ...) do{}while(0)
#define PWLogv(format, args) do{}while(0)
//#define PWLogInContext(context, format, ...) do{}while(0)
#endif

NS_INLINE void PWLogPush()
{
#if HAS_PWLOG
    pw_log_push();
#endif
}

NS_INLINE void PWLogPop()
{
#if HAS_PWLOG
    pw_log_pop();
#endif
}

NS_INLINE void PWLogSetBrackets (BOOL bracketInsets)
{
#if HAS_PWLOG
    pw_log_setBrackets (bracketInsets);
#endif
}

//NS_INLINE void PWLogAddContext(id aContext)
//{
//#if HAS_PWLOG
//    pw_log_addContext(aContext);
//#endif
//}

//NS_INLINE void PWLogRemoveContext(id aContext)
//{
//#if HAS_PWLOG
//    pw_log_removeContext(aContext);
//#endif
//}
    
#if defined __cplusplus
}
#endif

NS_ASSUME_NONNULL_END
