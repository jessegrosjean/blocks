//
//  BConfigurationElement.m
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import "BConfigurationElement.h"
#import "BExecutableExtensionProxy.h"
#import "BPlugin.h"
#import "BExtension.h"
#import "BLog.h"


@interface BConfigurationElement (BConfigurationElementPrivate)
- (BExtension *)extension;
@end

@implementation BConfigurationElement

#pragma mark Init

- (id)init {
	if (self = [super init]) {
	}
	return self;
}

#pragma mark Executable Extensions Factory

- (Class)executableExtensionClassFromAttribute:(NSString *)attributeName {
	return [self createExecutableExtensionFromAttribute:attributeName conformingToClass:nil conformingToProtocol:nil respondingToSelectors:nil];
}

- (Class)executableExtensionClassFromAttribute:(NSString *)attributeName conformingToClass:(Class)aClass conformingToProtocol:(Protocol *)aProtocol respondingToSelectors:(NSArray *)selectors {
	NSArray *executableExtensionClassNameAndSelector = [[self attributeForKey:attributeName] componentsSeparatedByString:@" "];
	NSString *executableExtensionClassName = [executableExtensionClassNameAndSelector objectAtIndex:0];
	Class executableExtensionClass = nil;
	
	if (!executableExtensionClassName) {
		BLogError(@"Failed to find executable extension class name attribute");
	} else {
		@try {			
			executableExtensionClass = [[[self declaringExtension] plugin] classNamed:executableExtensionClassName];
		} @catch (NSException *e) {
			BLogErrorWithException(e, [NSString stringWithFormat:@"Exception %@ while loading executable extension class %@", e, executableExtensionClassName]);
		}
	}
	
	if (!executableExtensionClass) return nil;
	
	if (aClass) {
		if (![executableExtensionClass isSubclassOfClass:aClass]) {
			BLogError([NSString stringWithFormat:@"Executable extension class %@ failed to conform to class %@", executableExtensionClass, aClass]);
			return nil;
		}
	}
	
	if (aProtocol) {
		if (![executableExtensionClass conformsToProtocol:aProtocol]) {
			BLogError([NSString stringWithFormat:@"Executable extension class %@ failed to conform to protocol %@", executableExtensionClass, aProtocol]);
			return nil;
		}
	}
	
	for (NSValue *eachValue in selectors) {
		SEL eachSelector = [eachValue pointerValue];
		if (![executableExtensionClass instancesRespondToSelector:eachSelector]) {
			BLogError([NSString stringWithFormat:@"Executable extension class %@ failed to respond to required selector %@", executableExtensionClass, NSStringFromSelector(eachSelector)]);
			return nil;
		}
	}
		
	return executableExtensionClass;
}

- (id)createExecutableExtensionFromAttribute:(NSString *)attributeName {
	return [self createExecutableExtensionFromAttribute:attributeName conformingToClass:nil conformingToProtocol:nil respondingToSelectors:nil];
}

- (id)createExecutableExtensionFromAttribute:(NSString *)attributeName conformingToClass:(Class)aClass conformingToProtocol:(Protocol *)aProtocol respondingToSelectors:(NSArray *)selectors {
	Class executableExtensionClass = [self executableExtensionClassFromAttribute:attributeName conformingToClass:aClass conformingToProtocol:aProtocol respondingToSelectors:selectors];
				
	if (executableExtensionClass) {
		@try {				
			NSArray *executableExtensionClassNameAndSelector = [[self attributeForKey:attributeName] componentsSeparatedByString:@" "];
			SEL instanceSelector = nil;
			
			if ([executableExtensionClassNameAndSelector count] > 1) {
				instanceSelector = NSSelectorFromString([executableExtensionClassNameAndSelector objectAtIndex:1]);
			}
			
			if (instanceSelector != nil) {
				return [executableExtensionClass performSelector:instanceSelector];
			} else {
				id executableExtension = [executableExtensionClass alloc];
				
				if ([executableExtension respondsToSelector:@selector(initWithConfigurationElement:)]) {
					executableExtension = [executableExtension initWithConfigurationElement:self];
				} else {
					executableExtension = [executableExtension init];
				}
				
				return executableExtension;
			}
		} @catch (NSException *e) {
			BLogErrorWithException(e, [NSString stringWithFormat:@"Exception %@ while loading instance of extension %@", e, self]);
		}
	}
	
	return nil;
}

- (id)createExecutableExtensionProxyFromAttribute:(NSString *)attributeName {
	return [self createExecutableExtensionProxyFromAttribute:attributeName conformingToClass:nil conformingToProtocol:nil respondingToSelectors:nil];
}

- (id)createExecutableExtensionProxyFromAttribute:(NSString *)attributeName conformingToClass:(Class)aClass conformingToProtocol:(Protocol *)aProtocol respondingToSelectors:(NSArray *)selectors {
	if (aClass != nil || aProtocol != nil || selectors != nil) {
		if (![self executableExtensionClassFromAttribute:attributeName conformingToClass:aClass conformingToProtocol:aProtocol respondingToSelectors:selectors]) {
			BLogError(@"failed to create executableExtensionProxy because proxied object class didn't conform to constraints.");
			return nil;
		}
	}
	
	return [[BExecutableExtensionProxy alloc] initWithConfigurationElement:self attributeName:attributeName];
}

#pragma mark Properties

- (BPlugin *)plugin {
	return [[self declaringExtension] plugin];
}

- (BExtension *)declaringExtension {
	BExtension *result = [self extension];
	if (!result) {
		result = [[self parent] declaringExtension];
	}
	return result;
}

@synthesize parent;
@synthesize name;
@synthesize attributes;
@synthesize value;

- (NSString *)attributeForKey:(NSString *)attributeName {
	return [attributes objectForKey:attributeName];
}

- (BOOL)booleanAttributeForKey:(NSString *)attributeName {
	return [@"yes" isEqualToString:[self attributeForKey:attributeName]];
}

- (NSInteger)integerAttributeForKey:(NSString *)attributeName {
	NSString *attribute = [self attributeForKey:attributeName];
	return attribute == nil ? 0 : [attribute integerValue];
}

- (CGFloat)floatAttributeForKey:(NSString *)attributeName {
	NSString *attribute = [self attributeForKey:attributeName];
	return attribute == nil ? 0 : [attribute doubleValue];
}

- (SEL)selectorAttributeForKey:(NSString *)attributeName {
	NSString *attribute = [self attributeForKey:attributeName];
	return attribute == nil ? NULL : NSSelectorFromString(attribute);
}

- (NSString *)localizedAttributeForKey:(NSString *)attributeName {
	return [[[self declaringExtension] plugin] localizedPluginXmlString:[self attributeForKey:attributeName]];
}

- (NSImage *)imageAttributeForKey:(NSString *)attributeName {
	return [[[self declaringExtension] plugin] imageNamed:[self attributeForKey:attributeName]];
}

- (id)executableExtensionAttributeForKey:(NSString *)attributeName {
	NSString *attribute = [self attributeForKey:attributeName];
	return attribute == nil || [attribute isEqualToString:@"nil"] ? nil : [self createExecutableExtensionFromAttribute:attributeName];
}

#pragma mark Child Configuration Elements

@synthesize children;

- (NSArray *)childrenNamed:(NSString *)aName {
	return [children filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", aName]];
}

#pragma mark Util

- (id)contentAsPropertyList {
	return [[xmlElement XMLString] propertyList];
}

- (NSXMLElement *)contentAsXmlElement {
	return xmlElement;
}

- (BOOL)assertKeysPresent:(NSArray *)keys {
	NSDictionary *elementAttributes = [self attributes];
	
	for (NSString *each in keys) {
		if (![elementAttributes objectForKey:each]) {
			BLogError([NSString stringWithFormat:@"Required key %@ not found in configuration element.", each]);
			return NO;
		}
	}
		
	return YES;
}

@end

@implementation BConfigurationElement (BConfigurationElementPrivate)

- (BExtension *)extension {
	return extension;
}

@end