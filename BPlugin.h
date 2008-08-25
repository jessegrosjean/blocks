//
//  BPlugin.h
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BRequirement;
@class BExtensionPoint;
@class BExtension;

@interface BPlugin : NSObject {
    NSBundle *bundle;
	NSString *label;
	NSString *version;
	NSString *identifier;
	NSMutableArray *requirements;
	NSMutableArray *extensionPoints;
	NSMutableArray *extensions;
	NSUInteger discoveryOrder;
	NSString *documentation;
}

#pragma mark Class Methods

+ (BPlugin *)pluginForClass:(Class)aClass;
							 
#pragma mark Init

- (id)initWithBundle:(NSBundle *)aBundle;
	
#pragma mark Properties

@property(readonly) NSBundle *bundle;
@property(readonly) NSString *label;
@property(readonly) NSString *version;
@property(readonly) NSString *identifier;
@property(readonly) NSArray *requirements;
@property(readonly) NSArray *extensionPoints;
@property(readonly) NSArray *extensions;
@property(readonly) NSString *documentation;
@property(readonly) NSArray *headerFilePaths;
	
#pragma mark Loading Bundle

@property(readonly) BOOL isLoaded;
- (BOOL)loadAndReturnError:(NSError **)error;

#pragma mark Util

- (Class)classNamed:(NSString *)className;
- (NSImage *)imageNamed:(NSString *)imageName;
- (NSString *)localizedPluginXmlString:(NSString *)string;

@end

@interface NSBundle (BPluginExtensions)
- (NSString *)version;
@end
