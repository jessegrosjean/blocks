//
//  BExtensionPoint.h
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BPlugin;

/*
 * An extension point declared in a plug-in. Except for the list of extensions plugged in to it, 
 * the information available for an extension point is obtained from the declaring plug-in's manifest (Plugin.xml) file.
 */
@interface BExtensionPoint : NSObject {
	BPlugin *plugin;
	NSString *identifier;
	NSString *documentation;
}

#pragma mark Properties

@property(readonly) BPlugin *plugin;
@property(readonly) NSString *identifier;
@property(readonly) NSString *documentation;

#pragma mark Extensions

@property(readonly) NSArray *extensions;
@property(readonly) NSArray *configurationElements;
- (NSArray *)configurationElementsNamed:(NSString *)name;

@end
