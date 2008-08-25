//
//  BExtensionRegistry.h
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BPlugin;
@class BExtensionPoint;

/*
 * The extension registry holds the master list of all discovered extension points and extensions.
 */
@interface BExtensionRegistry : NSObject {
	NSMutableArray *plugins;
	NSMutableArray *extensionPoints;
	NSMutableArray *extensions;
    NSMutableDictionary *pluginIDsToPlugins;
    NSMutableDictionary *extensionPointIDsToExtensionPoints;
    NSMutableDictionary *extensionPointIDsToExtensions;
    NSMutableDictionary *extensionPointIDsToConfigurationElements;
	BPlugin *mainBundlePlugin;
}

#pragma mark Class Methods

+ (id)sharedInstance;

#pragma mark Loading

- (void)loadMainExtension;

#pragma mark Querying

@property(readonly) NSArray *plugins;
- (BPlugin *)pluginFor:(NSString *)pluginID;
@property(readonly) NSArray *extensionPoints;
- (BExtensionPoint *)extensionPointFor:(NSString *)extensionPointID;
@property(readonly) NSArray *extensions;
- (NSArray *)extensionsFor:(NSString *)extensionPointID;
- (NSArray *)configurationElementsFor:(NSString *)extensionPointID;
	
@end