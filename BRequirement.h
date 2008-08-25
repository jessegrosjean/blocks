//
//  BRequirement.h
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BPlugin;

/*
 * A requirement specifies the bundles and bundler versions that this plugin needs to load.
 */
@interface BRequirement : NSObject {
	BPlugin *plugin;
	BOOL optional;
	NSString *version;
	NSString *requiredBundleIdentifier;
}

#pragma mark Properties

@property(readonly) BPlugin *plugin;
@property(readonly) BOOL optional;
@property(readonly) NSString *version;
@property(readonly) NSString *requiredBundleIdentifier;

#pragma mark Loading

@property(readonly) BOOL isLoaded;
- (BOOL)loadAndReturnError:(NSError **)error;
	
@end
