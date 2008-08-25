//
//  BLog.m
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import "BLog.h"
#include <asl.h>


@implementation BLog

static NSUInteger LoggingLevel = LOG_WARNING;

+ (NSUInteger)loggingLevel {
	return LoggingLevel;
}

+ (void)setLoggingLevel:(NSUInteger)level {
	LoggingLevel = level;
//	asl_set_filter(NULL, ASL_FILTER_MASK_UPTO(level));
}

+ (NSString *)typeStringForLevel:(NSUInteger)level {
	if (level >= LOG_DEBUG) return @"LOG_DEBUG";
	else if (level == LOG_INFO) return @"LOG_INFO";
	else if (level == LOG_NOTICE) return @"LOG_NOTICE";
	else if (level == LOG_WARNING) return @"LOG_WARNING";
	else if (level == LOG_ERR) return @"LOG_ERR";
	else if (level == LOG_CRIT) return @"LOG_CRIT";
	else if (level == LOG_ALERT) return @"LOG_ALERT";
	else return @"LOG_EMERG";
}

+ (void)logWithLevel:(NSUInteger)level lineNumber:(int)lineNumber fileName:(char *)fileName function:(char *)functionName format:(NSString *)format arguments:(va_list)args {
	if ([self loggingLevel] < level) return;
	//	asl_log(NULL, NULL, level, "%-32s %s", functionName, [(id)message UTF8String]);
	// wanting to switch over to asl_log, but things start to get to complicated... threading problems, and such.
	CFStringRef message = CFStringCreateWithFormatAndArguments(kCFAllocatorDefault, NULL, (CFStringRef)format, args);
	NSLog(@"%@ %-32s %@", [self typeStringForLevel:level], functionName, message);
	CFRelease(message);
}

+ (void)logWithLevel:(NSUInteger)level lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ... {
	if ([self loggingLevel] < level) return;
	va_list args;
	va_start(args, message);
	[self logWithLevel:level lineNumber:lineNumber fileName:fileName function:functionName format:message arguments:(va_list)args];
	va_end(args);
}

+ (void)logErrorWithException:(NSException *)exception lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ... {
	if ([self loggingLevel] < LOG_ERR) return;
	va_list args;
	va_start(args, message);
	[self logWithLevel:LOG_ERR lineNumber:lineNumber fileName:fileName function:functionName format:message arguments:(va_list)args];
	va_end(args);	
}

+ (void)assert:(BOOL)assertion lineNumber:(NSInteger)lineNumber fileName:(char *)fileName function:(char *)functionName message:(NSString *)message, ... {
	if (assertion) return;
	va_list args;
	va_start(args, message);
	message = [@"ASSERT " stringByAppendingString:message];
	[self logWithLevel:LOG_EMERG lineNumber:lineNumber fileName:fileName function:functionName format:message arguments:(va_list)args];
	va_end(args);
}

@end
