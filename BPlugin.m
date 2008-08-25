//
//  BPlugin.m
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import "BPlugin.h"
#import "BExtensionRegistry.h"
#import "BRequirement.h"
#import "BExtensionPoint.h"
#import "BExtension.h"
#import "BConfigurationElement.h"
#import "BLog.h"
#import "BLocks.h"


@interface BPlugin (BPluginPrivate)
- (BOOL)loadPluginXML;
@end

@interface BRequirement (BPluginPrivate)
- (id)initWithPlugin:(BPlugin *)aPlugin xmlElement:(NSXMLElement *)xmlElement;
@end

@interface BExtensionPoint (BPluginPrivate)
- (id)initWithPlugin:(BPlugin *)aPlugin xmlElement:(NSXMLElement *)xmlElement;
@end

@interface BExtension (BPluginPrivate)
- (id)initWithPlugin:(BPlugin *)aPlugin xmlElement:(NSXMLElement *)xmlElement;
@end

@interface BConfigurationElement (BPluginPrivate)
- (id)initWithExtension:(BExtension *)anExtension parent:(BConfigurationElement *)aParent xmlElement:(NSXMLElement *)xmlElement;
@end

@implementation BPlugin

#pragma mark Class Methods

+ (BPlugin *)pluginForClass:(Class)aClass {
	return [[BExtensionRegistry sharedInstance] pluginFor:[[NSBundle bundleForClass:aClass] bundleIdentifier]];
}

+ (NSXMLDTD *)pluginDTD {
	static NSXMLDTD *pluginDTD = nil;
	if (!pluginDTD) {
		NSError *error = nil;
		NSString *dtdPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"plugin" ofType:@"dtd"];
		pluginDTD = [[NSXMLDTD alloc] initWithContentsOfURL:[NSURL fileURLWithPath:dtdPath] options:0 error:&error];
		if (!pluginDTD) {
			BLogError([NSString stringWithFormat:@"failed to load XML dtd with error %@", error]);
		}
		[pluginDTD setName:@"plugin"];
	}
	return pluginDTD;
}

#pragma mark Init

static NSInteger discoveryOrderCounter = 0;

- (id)initWithBundle:(NSBundle *)aBundle {
	if (self = [super init]) {
		discoveryOrder = discoveryOrderCounter++;
		bundle = aBundle;
		requirements = [[NSMutableArray alloc] init];
		extensionPoints = [[NSMutableArray alloc] init];
		extensions = [[NSMutableArray alloc] init];
		
		if (![self loadPluginXML]) {
			BLogError([NSString stringWithFormat:@"failed loadPluginXML for bundle %@", [bundle bundleIdentifier]]);
			return nil;
		}
	}
	return self;
}


#pragma mark Properties

@synthesize bundle;
@synthesize label;
@synthesize version;
@synthesize identifier;
@synthesize requirements;
@synthesize extensionPoints;
@synthesize extensions;
@synthesize documentation;

- (NSString *)documentation {
	if (!documentation) {
		documentation = [NSString stringWithContentsOfFile:[self.bundle pathForResource:self.identifier ofType:@"markdown"]];
		if (!documentation) {
			documentation = BLocalizedString(@"No documentation file could be found for this plugin", nil);
		}
	}
	return documentation;
}

- (NSArray *)headerFilePaths {
	NSMutableArray *headerFilePaths = [NSMutableArray array];
	NSString *headersFolder = [NSString stringWithFormat:@"%@/Contents/Headers/", [bundle bundlePath]];
	for (NSString *each in [[NSFileManager defaultManager] directoryContentsAtPath:headersFolder]) {
		[headerFilePaths addObject:[NSString stringWithFormat:@"%@%@", headersFolder, each]];
	}
	return headerFilePaths;
}

#pragma mark Loading Bundle

- (BOOL)isLoaded {
	return [self.bundle isLoaded];
}

- (BOOL)loadAndReturnError:(NSError **)error {
    if (![self isLoaded]) {
		for (BRequirement *each in self.requirements) {
//			if (![each isLoaded]) {
				if ([each loadAndReturnError:error]) {
					BLogInfo(([NSString stringWithFormat:@"Loaded code for requirement %@ by plugin %@", each, self.identifier]));
				} else {
					if ([each optional]) {
						BLogError(([NSString stringWithFormat:@"Failed to load code for optioinal requirement %@ by plugin %@", each, self.identifier]));
					} else {
						BLogError(([NSString stringWithFormat:@"Failed to load code for requirement %@ by plugin %@", [each requiredBundleIdentifier], self.identifier]));
						BLogError(([NSString stringWithFormat:@"Failed to load code for plugin with id %@", self.identifier]));
						return NO;
					}
				}
//			}
		}
								
		if ([self.bundle loadAndReturnError:error]) {
			BLogInfo([NSString stringWithFormat:@"Loaded plugin %@", self.identifier]);
		} else {
			BLogError(@"Failed to load bundle with id %@: %@", self.identifier, bundle);
			return NO;
		}
	}
	
	return YES;
}

#pragma mark Util

- (Class)classNamed:(NSString *)className {
	NSError *error = nil;
	Class result = nil;
	
	if ([self loadAndReturnError:&error]) {
		result = [self.bundle classNamed:className];
	}
	
	if (!result) {
		result = NSClassFromString(className);
	}
	
	return result;
}

/*
 * First checks main bundle for image, then checks plugin bundle if no image was found.
 */
- (NSImage *)imageNamed:(NSString *)imageName {
	NSString *imageNamePluginUniqueName = [NSString stringWithFormat:@"%@.%@", self.identifier, imageName];
	NSImage *image = [NSImage imageNamed:imageNamePluginUniqueName];
	
	if (!image) {
		image = [[NSImage alloc] initWithContentsOfFile:[self.bundle pathForImageResource:imageName]];
		[image setName:imageNamePluginUniqueName];
	}
	
    return image;	
}

/*
 * Allows [NSBundle main] to override localizations in plugins PluginXml.strings file with its own.
 */
- (NSString *)localizedPluginXmlString:(NSString *)string {
	if ([string length] > 0 && [string characterAtIndex:0] == '%') {
		string = [string substringFromIndex:1];
		NSString *keyNotFoundMarker = @"BKeyNotFound";
		NSString *localizedString = [[NSBundle mainBundle] localizedStringForKey:string value:keyNotFoundMarker table:@"PluginXml"];
		
		if ([keyNotFoundMarker isEqualToString:localizedString]) {
			string = [self.bundle localizedStringForKey:string value:@"" table:@"PluginXml"];	
		} else {
			string = localizedString;
		}
	}
	
	return string;
}

@end

@implementation BPlugin (BPluginPrivate)

- (BOOL)loadPluginXML {
	NSError *error = nil;
	NSString *xmlPath = [bundle pathForResource:@"Plugin" ofType:@"xml"];
	NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath];
	NSXMLDocument *document = xmlData != nil ?[[NSXMLDocument alloc] initWithData:xmlData options:0 error:&error] : nil;
	
	if (!document) {
		BLogError([NSString stringWithFormat:@"failed to load Plugin.xml resource for bundle %@ with error %@", bundle, error]);
		return NO;
	}
	
//	[document setDTD:[BPlugin pluginDTD]];
//	if (![document validateAndReturnError:&error]) {
//		BLogError([NSString stringWithFormat:@"failed to validate Plugin.xml resource for bundle %@ with error %@", bundle, error]);
//	}
	
	NSXMLElement *rootElement = [document rootElement];
	
	label = [[rootElement attributeForName:@"label"] objectValue];
	version = [[rootElement attributeForName:@"version"] objectValue];
	identifier = [[rootElement attributeForName:@"id"] objectValue];	

	if (!version || [[version componentsSeparatedByString:@"."] count] != 3) {
		BLogError([NSString stringWithFormat:@"failed to load Plugin.xml resource for bundle %@ because plugins version number isn't present or doesn't conform to #.#.#", bundle]);
		return NO;
	}
	
	for (NSXMLElement *each in [rootElement elementsForName:@"requirement"]) {
		BRequirement *requirement = [[BRequirement alloc] initWithPlugin:self xmlElement:each];
		if (!requirement.version || [[requirement.version componentsSeparatedByString:@"."] count] != 3) {
			BLogError([NSString stringWithFormat:@"failed to load Plugin.xml resource for bundle %@ because the version number declared by the %@ requirment isn't present or doesn't conform to #.#.#", bundle, requirement]);
			return NO;
		}
		[requirements addObject:requirement];
	}
	
	for (NSXMLElement *each in [rootElement elementsForName:@"extension-point"]) {
		[extensionPoints addObject:[[BExtensionPoint alloc] initWithPlugin:self xmlElement:each]];
	}

	for (NSXMLElement *each in [rootElement elementsForName:@"extension"]) {
		[extensions addObject:[[BExtension alloc] initWithPlugin:self xmlElement:each]];
	}
		
    return YES;
}

@end

@implementation BRequirement (BPluginPrivate)

- (id)initWithPlugin:(BPlugin *)aPlugin xmlElement:(NSXMLElement *)xmlElement {
	if (self = [super init]) {
		plugin = aPlugin;
		optional = [[[xmlElement attributeForName:@"optional"] objectValue] isEqualToString:@"true"];
		version = [[xmlElement attributeForName:@"version"] objectValue];
		requiredBundleIdentifier = [[xmlElement attributeForName:@"bundle"] objectValue];
	}
	return self;
}

@end

@implementation BExtensionPoint (BPluginPrivate)

- (id)initWithPlugin:(BPlugin *)aPlugin xmlElement:(NSXMLElement *)xmlElement {
	if (self = [super init]) {
		plugin = aPlugin;
		identifier = [NSString stringWithFormat:@"%@.%@",[aPlugin identifier], [[xmlElement attributeForName:@"id"] objectValue]];
	}
	return self;
}

@end

@implementation BExtension (BPluginPrivate)

- (id)initWithPlugin:(BPlugin *)aPlugin xmlElement:(NSXMLElement *)xmlElement {
	if (self = [super init]) {
		plugin = aPlugin;
		label = [[xmlElement attributeForName:@"label"] objectValue];
		
		NSString *processOrderString = [[xmlElement attributeForName:@"processOrder"] stringValue];
		if (processOrderString) {
			processOrder = [processOrderString doubleValue];
		}

		extensionPointUniqueIdentifier = [[xmlElement attributeForName:@"point"] objectValue];
		
		NSArray *elementChildren = [xmlElement children];
		NSUInteger count = [elementChildren count];
		
		if (count > 0) {
			configurationElements = [[NSMutableArray alloc] initWithCapacity:count];
			NSUInteger i = 0;
			
			while (i < count) {
				[configurationElements addObject:[[BConfigurationElement alloc] initWithExtension:self parent:nil xmlElement:[elementChildren objectAtIndex:i]]];
				i++;
			}
		}
	}
	return self;
}

@end

@implementation BConfigurationElement (BPluginPrivate)

- (id)initWithExtension:(BExtension *)anExtension parent:(BConfigurationElement *)aParent xmlElement:(NSXMLElement *)anXmlElement {
	if (self = [super init]) {
		xmlElement = anXmlElement;
		extension = anExtension;
		parent = aParent;
		name = [xmlElement name];
		value = [xmlElement objectValue];
			
		NSArray *xmlElementAttributes = [xmlElement attributes];
		NSUInteger count = [xmlElementAttributes count];

		if (count > 0) {
			attributes = [[NSMutableDictionary alloc] initWithCapacity:count];
			NSUInteger i = 0;
			
			while (i < count) {
				NSXMLNode *eachNode = [xmlElementAttributes objectAtIndex:i];
				[attributes setObject:[eachNode objectValue] forKey:[eachNode name]];
				i++;
			}
		}
		
		NSArray *elementChildren = [xmlElement children];
		count = [elementChildren count];
		
		if (count > 0) {
			children = [[NSMutableArray alloc] initWithCapacity:count];
			NSUInteger i = 0;
			
			while (i < count) {
				[children addObject:[[BConfigurationElement alloc] initWithExtension:extension parent:self xmlElement:[elementChildren objectAtIndex:i]]];
				i++;
			}
		}
	}
	return self;
}

@end

@implementation NSBundle (BPluginExtensions)

- (NSString *)version {
	return [[self infoDictionary] objectForKey:(NSString *)kCFBundleVersionKey];
}

@end
