//
//  BConfigurationElement.h
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BPlugin;
@class BExtension;

/*
 * Configuration elements are used to instantiate objects extending from a particular extension point.
 * A configuration element, with its attributes and children, directly reflects the content 
 * and structure of the extension section within the declaring plug-in's manifest (Plugin.xml) file.
 */
@interface BConfigurationElement : NSObject {
	BExtension *extension;
	BConfigurationElement *parent;
	NSString *name;
	NSMutableDictionary *attributes;
	NSMutableArray *children;
	id value;
	NSXMLElement *xmlElement;
}

#pragma mark Executable Extensions Factory

- (Class)executableExtensionClassFromAttribute:(NSString *)attributeName;
- (Class)executableExtensionClassFromAttribute:(NSString *)attributeName conformingToClass:(Class)aClass conformingToProtocol:(Protocol *)aProtocol respondingToSelectors:(NSArray *)selectors;
- (id)createExecutableExtensionFromAttribute:(NSString *)attributeName;
- (id)createExecutableExtensionFromAttribute:(NSString *)attributeName conformingToClass:(Class)aClass conformingToProtocol:(Protocol *)aProtocol respondingToSelectors:(NSArray *)selectors;
- (id)createExecutableExtensionProxyFromAttribute:(NSString *)attributeName;
- (id)createExecutableExtensionProxyFromAttribute:(NSString *)attributeName conformingToClass:(Class)aClass conformingToProtocol:(Protocol *)aProtocol respondingToSelectors:(NSArray *)selectors;

#pragma mark Attributes

@property(readonly) BPlugin *plugin;
@property(readonly) BExtension *declaringExtension;
@property(readonly) BConfigurationElement *parent;
@property(readonly) NSString *name;
@property(readonly) NSDictionary *attributes;
@property(readonly) id value;
- (NSString *)attributeForKey:(NSString *)attributeName;
- (BOOL)booleanAttributeForKey:(NSString *)attributeName;
- (NSInteger)integerAttributeForKey:(NSString *)attributeName;
- (CGFloat)floatAttributeForKey:(NSString *)attributeName;
- (SEL)selectorAttributeForKey:(NSString *)attributeName;
- (NSString *)localizedAttributeForKey:(NSString *)attributeName;
- (NSImage *)imageAttributeForKey:(NSString *)attributeName;
- (id)executableExtensionAttributeForKey:(NSString *)attributeName;

#pragma mark Child Configuration Elements

@property(readonly) NSArray *children;
- (NSArray *)childrenNamed:(NSString *)aName;

#pragma mark Util

@property(readonly) id contentAsPropertyList;
@property(readonly) NSXMLElement *contentAsXmlElement;
- (BOOL)assertKeysPresent:(NSArray *)keys;

@end

@interface NSObject (BConfigurationElement)
- (id)initWithConfigurationElement:(BConfigurationElement *)aConfigurationElement;
@end