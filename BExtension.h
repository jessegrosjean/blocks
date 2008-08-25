//
//  BExtension.h
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BConfigurationElement;


@class BPlugin;

/*
 * An extension declared in a plug-in. All information is obtained from the declaring plug-in's
 * manifest (Plugin.xml) file.
 */
@interface BExtension : NSObject {
	BPlugin *plugin;
	NSString *label;
	CGFloat processOrder;
	NSString *extensionPointUniqueIdentifier;
	NSMutableArray *configurationElements;
}

#pragma mark Properties

@property(readonly) BPlugin *plugin;
@property(readonly) NSString *label;
@property(readonly) NSString *extensionPointUniqueIdentifier;
	
#pragma mark Configuration Elements

@property(readonly) NSArray *configurationElements;
- (NSArray *)configurationElementsNamed:(NSString *)name;

@end
