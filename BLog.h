//
//  BLog.h
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <syslog.h>

/* 
 * Logging levels from syslog.h
 *
 * priorities/facilities are encoded into a single 32-bit quantity, where the
 * bottom 3 bits are the priority (0-7) and the top 28 bits are the facility
 * (0-big number).  Both the priorities and the facilities map roughly
 * one-to-one to strings in the syslogd(8) source code.  This mapping is
 * included in this file.
 *
 * priorities (these are ordered)
 *
 * LOG_EMERG	0	// system is unusable
 * LOG_ALERT	1	// action must be taken immediately
 * LOG_CRIT		2	// critical conditions
 * LOG_ERR		3	// error conditions
 * LOG_WARNING	4	// warning conditions
 * LOG_NOTICE	5	// normal but significant condition
 * LOG_INFO		6	// informational
 * LOG_DEBUG	7	// debug-level messages
 */

#define LOCATION_PARAMETERS lineNumber:__LINE__ fileName:(char *)__FILE__ function:(char *)__PRETTY_FUNCTION__

#define BLogEmergency(...) [BLog logWithLevel:LOG_EMERG LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogAlert(...) [BLog logWithLevel:LOG_ALERT LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogCritical(...) [BLog logWithLevel:LOG_CRIT LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogError(...) [BLog logWithLevel:LOG_ERR LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogWarning(...) [BLog logWithLevel:LOG_WARNING LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogNotice(...) [BLog logWithLevel:LOG_NOTICE LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogInfo(...) [BLog logWithLevel:LOG_INFO LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogDebug(...) [BLog logWithLevel:LOG_DEBUG LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogErrorWithException(e, ...) [BLog logErrorWithException:e LOCATION_PARAMETERS message:__VA_ARGS__]
#define BLogAssert(assertion, ...) [BLog assert:assertion LOCATION_PARAMETERS message:__VA_ARGS__]

@interface BLog : NSObject {
}

+ (NSUInteger)loggingLevel;
+ (void)setLoggingLevel:(NSUInteger)level;
+ (void)logWithLevel:(NSUInteger)level lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)functionName format:(NSString *)format arguments:(va_list)args;
+ (void)logWithLevel:(NSUInteger)level lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ...;
+ (void)logErrorWithException:(NSException *)exception lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ...;
+ (void)assert:(BOOL)assertion lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)methodName message:(NSString *)formatStr, ... ;

@end

