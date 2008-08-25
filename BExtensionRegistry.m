//
//  BExtensionRegistry.m
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import "BExtensionRegistry.h"
#import "BLog.h"
#import "BPlugin.h"
#import "BExtension.h"
#import "BRequirement.h"
#import "BExtensionPoint.h"
#import "BConfigurationElement.h"


@interface BExtensionRegistry (BExtensionRegistryPrivate)
- (void)discoverPlugins;
- (void)loadMainBundlePluginSharedApplication;
- (void)registerPlugin:(BPlugin *)plugin;
- (void)registerExtensionPointsFor:(BPlugin *)plugin;
- (void)registerExtensionsFor:(BPlugin *)plugin;
- (NSArray *)pluginSearchPaths;
@end

@implementation BExtensionRegistry

#pragma mark class methods

+ (id)sharedInstance {
	static BExtensionRegistry *sharedInstance = nil;
	if (sharedInstance == nil) {
        sharedInstance = [self alloc];
		sharedInstance = [sharedInstance init];
	}
	return sharedInstance;
}

#pragma mark Init

- (id)init {
	if (self = [super init]) {
		plugins = [[NSMutableArray alloc] init];
		extensionPoints = [[NSMutableArray alloc] init];
		extensions = [[NSMutableArray alloc] init];
		pluginIDsToPlugins = [[NSMutableDictionary alloc] init];
		extensionPointIDsToExtensions = [[NSMutableDictionary alloc] init];
		extensionPointIDsToExtensionPoints = [[NSMutableDictionary alloc] init];
		extensionPointIDsToConfigurationElements = [[NSMutableDictionary alloc] init];
		[self discoverPlugins];
		[self loadMainBundlePluginSharedApplication];
		[[NSAppleEventManager sharedAppleEventManager] setEventHandler:self andSelector:@selector(handleGetSDEFEvent:withReplyEvent:) forEventClass:'ascr' andEventID:'gsdf'];
	}
	return self;
}

#pragma mark Loading

- (void)loadMainExtension {
	for (BConfigurationElement *each in [self configurationElementsFor:@"com.blocks.Blocks.main"]) {
		[each createExecutableExtensionFromAttribute:@"class"];
	}
}

#pragma mark Querying

@synthesize plugins;

- (BPlugin *)pluginFor:(NSString *)pluginID {
	return [pluginIDsToPlugins objectForKey:pluginID];
}

@synthesize extensionPoints;

- (BExtensionPoint *)extensionPointFor:(NSString *)extensionPointID {
	return [extensionPointIDsToExtensionPoints objectForKey:extensionPointID];
}

@synthesize extensions;

- (NSArray *)extensionsFor:(NSString *)extensionPointID {
	return [extensionPointIDsToExtensions objectForKey:extensionPointID];
}

- (NSArray *)configurationElementsFor:(NSString *)extensionPointID {	
	NSMutableArray *configurationElements = [extensionPointIDsToConfigurationElements objectForKey:extensionPointID];

	if (!configurationElements) {
		configurationElements = [NSMutableArray array];
		
		for (BExtension *each in [self extensionsFor:extensionPointID]) {
			[configurationElements addObjectsFromArray:[each configurationElements]];
		}

		[extensionPointIDsToConfigurationElements setObject:configurationElements forKey:extensionPointID];
	}
	
	return configurationElements;
}

@end

@implementation BExtensionRegistry (BRegistryPrivate)

- (void)discoverPlugins {
	// Both blocks bundle and mainBundle are special cases, treated as plugins even though they don't end with .plugin extension and don't exist in plugin search paths.
	// This is done so that they can declare Plugin.xml file and so that the main bundle can declare requirments so that it can make use of other plugin classes.
	mainBundlePlugin = [[BPlugin alloc] initWithBundle:[NSBundle mainBundle]];
    [self registerPlugin:mainBundlePlugin];
    [self registerPlugin:[[BPlugin alloc] initWithBundle:[NSBundle bundleForClass:[self class]]]];
	
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSMutableArray *pluginSearchPaths = [[self pluginSearchPaths] mutableCopy];
    NSString *eachSearchPath;
	
	while (eachSearchPath = [pluginSearchPaths lastObject]) {
		[pluginSearchPaths removeLastObject];
		
		NSDirectoryEnumerator *directoryEnumerator = [fileManager enumeratorAtPath:eachSearchPath];
		NSString* eachPath;
		
		while (eachPath = [directoryEnumerator nextObject]) {
			if ([[eachPath pathExtension] caseInsensitiveCompare:@"plugin"] == NSOrderedSame) {
				[directoryEnumerator skipDescendents];
				
				eachPath = [eachSearchPath stringByAppendingPathComponent:eachPath];
				
				NSBundle *bundle = [NSBundle bundleWithPath:eachPath];
				BPlugin *plugin = [[BPlugin alloc] initWithBundle:bundle];
				
				if (!plugin) {
					BLogWarning(([NSString stringWithFormat:@"failed to create plugin for path: %@", eachPath]));
				} else {
					[self registerPlugin:plugin];
					[pluginSearchPaths addObject:[bundle builtInPlugInsPath]]; // search within plugin for more
				}
			}
		}
    }

	for (BPlugin *eachPlugin in [self plugins]) {
		[self registerExtensionPointsFor:eachPlugin];
    }

	for (BPlugin *eachPlugin in [self plugins]) {
		[self registerExtensionsFor:eachPlugin];
    }
		
	NSSortDescriptor *sortByProcessOrder = [[NSSortDescriptor alloc] initWithKey:@"processOrder" ascending:YES];
	NSSortDescriptor *sortByPluginDiscoveryOrder = [[NSSortDescriptor alloc] initWithKey:@"plugin.discoveryOrder" ascending:YES];
	NSArray *extensionsSortDescriptors = [NSArray arrayWithObjects:sortByProcessOrder, sortByPluginDiscoveryOrder, nil];
	
	for (NSString *eachExtensionPointID in [extensionPointIDsToExtensions keyEnumerator]) {
		[[extensionPointIDsToExtensions objectForKey:eachExtensionPointID] sortUsingDescriptors:extensionsSortDescriptors];
	}
}

- (void)loadMainBundlePluginSharedApplication {
	[[mainBundlePlugin classNamed:[[mainBundlePlugin.bundle infoDictionary] objectForKey:@"NSPrincipalClass"]] sharedApplication];
}

- (void)registerPlugin:(BPlugin *)plugin {
	BLogAssert([[plugin identifier] isEqualToString:[[plugin bundle] bundleIdentifier]], @"plugin identifer %@ does not equal bundle identifier %@", [plugin identifier], [[plugin bundle] bundleIdentifier]);
//	BLogAssert([[plugin version] isEqualToString:[[plugin bundle] version]], @"plugin version %@ does not equal bundle CFBundleVersion %@", [plugin version], [[plugin bundle] version]);
	
    if ([pluginIDsToPlugins objectForKey:[plugin identifier]] != nil) {
		BLogWarning([NSString stringWithFormat:@"plugin id %@ not unique, replacing old with new", [plugin identifier]]);
    }
	
	[plugins addObject:plugin];
    [pluginIDsToPlugins setObject:plugin forKey:[plugin identifier]];

	BLogInfo([NSString stringWithFormat:@"Registered plugin %@", [plugin identifier]]);
}

- (void)registerExtensionPointsFor:(BPlugin *)plugin {
    for (BExtensionPoint *eachExtensionPoint in [plugin extensionPoints]) {
		if ([extensionPointIDsToExtensionPoints objectForKey:[eachExtensionPoint identifier]]) {
			[extensionPoints removeObject:[extensionPointIDsToExtensionPoints objectForKey:[eachExtensionPoint identifier]]];
			BLogWarning([NSString stringWithFormat:@"extension point id %@ not unique, replacing old with new", [eachExtensionPoint identifier]]);
		}
		[extensionPoints addObject:eachExtensionPoint];
		[extensionPointIDsToExtensionPoints setObject:eachExtensionPoint forKey:[eachExtensionPoint identifier]];
    }
}

- (void)registerExtensionsFor:(BPlugin *)plugin {
    for (BExtension *eachExtension in [plugin extensions]) {
		NSString *eachExtensionPointUniqueIdentifier = [eachExtension extensionPointUniqueIdentifier];

		if (![self extensionPointFor:eachExtensionPointUniqueIdentifier]) {
			BLogWarning([NSString stringWithFormat:@"no extension point found for extension %@ declared by plugin %@, so that extension will never be loaded.", eachExtensionPointUniqueIdentifier, [plugin identifier]]);
		}
		
		NSMutableArray *pointExtensions = [extensionPointIDsToExtensions objectForKey:eachExtensionPointUniqueIdentifier];
		if (!pointExtensions) {
			pointExtensions = [NSMutableArray array];
			[extensionPointIDsToExtensions setObject:pointExtensions forKey:eachExtensionPointUniqueIdentifier];
		}
		[pointExtensions addObject:eachExtension];
	}
}

- (NSArray *)pluginSearchPaths {
	NSMutableArray *pluginSearchPaths = [NSMutableArray array];
	NSString *applicationSupportSubpath = [NSString stringWithFormat:@"Application Support/%@/PlugIns", [[NSProcessInfo processInfo] processName]];
	NSEnumerator *searchPathEnumerator = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES) objectEnumerator];
	
	for (NSString *eachSearchPath in searchPathEnumerator) {
		NSString *eachPluginPath = [eachSearchPath stringByAppendingPathComponent:applicationSupportSubpath];
		if (![pluginSearchPaths containsObject:eachPluginPath]) {
			[pluginSearchPaths addObject:eachPluginPath];
		}
	}
	
	for (NSBundle *eachBundle in [NSBundle allBundles]) {
		NSString *eachPluginPath = [eachBundle builtInPlugInsPath];
		if (![pluginSearchPaths containsObject:eachPluginPath]) {
			[pluginSearchPaths addObject:eachPluginPath];
		}
	}
	
	return pluginSearchPaths;
}

- (void)handleGetSDEFEvent:(NSAppleEventDescriptor *)event withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
	NSError *error = nil;
	NSBundle *blocksBundle = [NSBundle bundleForClass:[self class]];
	NSString *blocksSDEFPath = [blocksBundle pathForResource:@"BlocksDefault" ofType:@"sdef"];
	
	BLogInfo(@"Will parse sdef %@", blocksSDEFPath);
	
	NSXMLDocument *mergedOSAScriptingDefinition = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:blocksSDEFPath] options:0 error:&error];

	BLogAssert(mergedOSAScriptingDefinition != nil, [NSString stringWithFormat:@"mergedOSAScriptingDefinition failed to load with error %@", error]);
	
	NSXMLElement *mergedOSAScriptingDefinitionRoot = [mergedOSAScriptingDefinition rootElement];
	
	[[NSProcessInfo processInfo] processName];
	
	for (BPlugin *eachPlugin in [[BExtensionRegistry sharedInstance] plugins]) {
		NSDictionary *infoDictionary = [eachPlugin.bundle infoDictionary];
		
		if ([[infoDictionary objectForKey:@"NSAppleScriptEnabled"] isEqualToString:@"YES"]) {
			NSString *osaScriptingDefinitionName = [infoDictionary objectForKey:@"OSAScriptingDefinition"];
			
			if (eachPlugin.bundle == [NSBundle mainBundle]) {
				BLogAssert([osaScriptingDefinitionName isEqualToString:@"dynamic"], @"main bundle of NSAppleScriptEnabled blocks apps should have OSAScriptingDefinition set to dynamic so that plugin sdefs will be found.");
			} else {
				NSString *osaScriptingDefinitionPath = [eachPlugin.bundle pathForResource:osaScriptingDefinitionName ofType:nil];
				if (osaScriptingDefinitionPath) {
					BLogInfo(@"Will parse sdef %@", osaScriptingDefinitionPath);

					NSXMLDocument *eachOSAScriptingDefinition = [[NSXMLDocument alloc] initWithContentsOfURL:[NSURL fileURLWithPath:osaScriptingDefinitionPath] options:0 error:&error];
					
					if (eachOSAScriptingDefinition) {
						if ([eachPlugin loadAndReturnError:&error]) {
							for (NSXMLElement *eachSuiteElement in [[eachOSAScriptingDefinition rootElement] elementsForName:@"suite"]) {
								[mergedOSAScriptingDefinitionRoot addChild:[eachSuiteElement copy]];
							}
						} else {
							BLogError([NSString stringWithFormat:@"failed to load plugin %@ and so will not include plugins OSAScriptingDefinitaion", eachPlugin]);
						}
					} else {
						BLogError([NSString stringWithFormat:@"failed to load OSAScriptingDefinitaion %@", osaScriptingDefinitionPath]);
					}
				}
			}
		}
    }
		
	[replyEvent setDescriptor:[NSAppleEventDescriptor descriptorWithDescriptorType:typeUTF8Text data:[mergedOSAScriptingDefinition XMLData]] forKeyword:keyDirectObject];
}

@end