//
//  BExecutableExtensionProxy.m
//  Blocks
//
//  Created by Jesse Grosjean on 8/22/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import "BExecutableExtensionProxy.h"
#import "BConfigurationElement.h"
#import "BLog.h"


@implementation BExecutableExtensionProxy

#pragma mark Init

- (id)initWithConfigurationElement:(BConfigurationElement *)aConfigurationElement attributeName:(NSString *)anAttributeName {
	configurationElement = aConfigurationElement;
	attributeName = anAttributeName;
	return self;
}

#pragma mark Delegate

- (id)delegate {
	if (!delegate) {
		delegate = [configurationElement createExecutableExtensionFromAttribute:attributeName];
		BLogAssert(delegate != nil, @"proxied object should have been created.");
	}
	return delegate;
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)selector {
	return [[self delegate] methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation*)invocation {
	[invocation invokeWithTarget:[self delegate]];
}

@end
