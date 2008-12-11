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

// From http://code.google.com/p/ilcrashreporter-ng/
+ (NSString*)gatherConsoleLogFromDate:(NSDate*)date {
	aslmsg query = asl_new(ASL_TYPE_QUERY);
	
	if(query == NULL) return nil;
	
	const uint32_t senderQueryOptions = ASL_QUERY_OP_EQUAL|ASL_QUERY_OP_CASEFOLD|ASL_QUERY_OP_SUBSTRING;
	const int aslSetSenderQueryReturnCode = asl_set_query(query, ASL_KEY_SENDER, [[[NSProcessInfo processInfo] processName] UTF8String], senderQueryOptions);
	if(aslSetSenderQueryReturnCode != 0) return nil;
	
	static const size_t timeBufferLength = 64;
	char oneHourAgo[timeBufferLength];
	snprintf(oneHourAgo, timeBufferLength, "%0lf", [date timeIntervalSince1970]);
	const int aslSetTimeQueryReturnCode = asl_set_query(query, ASL_KEY_TIME, oneHourAgo, ASL_QUERY_OP_GREATER_EQUAL);
	if(aslSetTimeQueryReturnCode != 0) return nil;
	
	aslresponse response = asl_search(NULL, query);
	
	NSMutableString* searchResults = [NSMutableString string];

	for(;;) {
		aslmsg message = aslresponse_next(response);
		if(message == NULL) break;
		const char* time = asl_get(message, ASL_KEY_TIME);
		if(time == NULL) continue;
		const char* level = asl_get(message, ASL_KEY_LEVEL);
		if(level == NULL) continue;
		const char* messageText = asl_get(message, ASL_KEY_MSG);
		if(messageText == NULL) continue;
		NSCalendarDate* date = [NSCalendarDate dateWithTimeIntervalSince1970:atof(time)];
		[searchResults appendFormat:@"%@[%s]: %s\n", [date description], level, messageText];
	}
	
	aslresponse_free(response);
	
	return searchResults;
}

@end
