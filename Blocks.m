//
//  Blocks.m
//  Blocks
//
//  Created by Jesse Grosjean on 2/21/08.
//  Copyright 2008 Blocks. All rights reserved.
//

#import "Blocks.h"
#import <objc/objc-class.h>


@implementation NSObject (BlocksMethodSwizzle)

// derived from http://rentzsch.com/trac/wiki/JRSwizzle
+ (BOOL)replaceMethod:(SEL)originalSelelector withMethod:(SEL)replacementSelector {
	Method originalMethod = class_getInstanceMethod(self, originalSelelector);	
	if (originalMethod == NULL) {
		BLogError(@"original method %@ not found for class %@", NSStringFromSelector(originalSelelector), [self className]);
		return NO;
	}
	
	Method replacementMethod = class_getInstanceMethod(self, replacementSelector);
	if (replacementMethod == NULL) {
		BLogError(@"original method %@ not found for class %@", NSStringFromSelector(replacementSelector), [self className]);
		return NO;
	}
	
	class_addMethod(self, originalSelelector, class_getMethodImplementation(self, originalSelelector), method_getTypeEncoding(originalMethod));
	class_addMethod(self, replacementSelector, class_getMethodImplementation(self, replacementSelector), method_getTypeEncoding(replacementMethod));	
	method_exchangeImplementations(class_getInstanceMethod(self, originalSelelector), class_getInstanceMethod(self, replacementSelector));
	return YES;
}

@end