//
//  PWFoundationDebugOptionGroup.m
//  PWFoundation
//
//  Created by Frank Illenberger on 14.01.13.
//
//

#import "PWFoundationDebugOptionGroup.h"
#import "PWDispatch.h"
#import "NSObject-PWExtensions.h"

DEBUG_OPTION_DEFINE_GROUP (PWFoundationDebugGroup, PWRootDebugOptionGroup, @"Foundation", @"")

DEBUG_OPTION_ACTIONBLOCK (PWFoundationThrowException, PWFoundationDebugGroup, @"Raise Exception", @"",
                          ^(){ [NSException raise:NSInternalInconsistencyException format:@"Test Exception"]; })

DEBUG_OPTION_ACTIONBLOCK (PWFoundationThrowExceptionOnNonMainThread, PWFoundationDebugGroup, @"Raise Exception On Non-Main Thread", @"",
                          ^(){
                              [PWDispatchQueue.globalDefaultPriorityQueue asynchronouslyDispatchBlock:^{
                                  [NSException raise:NSInternalInconsistencyException format:@"Test Exception"];
                              }];
                          })

DEBUG_OPTION_ACTIONBLOCK (PWFoundationCreateCrash, PWFoundationDebugGroup, @"Create Crash", @"",
                          ^(){
#ifndef __clang_analyzer__
                              int* ptr = (int*)0; *ptr = 42;
#endif
                          })

DEBUG_OPTION_ACTIONBLOCK (PWFoundationCreateCrashWithOnformation, PWFoundationDebugGroup, @"Create Crash with information", @"",
                          ^(){
                              PWNoteInCrashReportForPerformingBlock(@"Something bad happened", ^{
                                  NSArray* array = @[];
                                  __unused id object = array[2];
                              });
                          })
