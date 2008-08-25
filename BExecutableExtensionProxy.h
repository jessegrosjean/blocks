//
//  BExecutableExtensionProxy.h
//  Blocks
//
//  Created by Jesse Grosjean on 8/22/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class BConfigurationElement;

/*
 * An executable extension proxy can be treated as an executable extension, except it loads lazily.
 * This allows an extension point to deal with 'instances' of an extension without actually needing to
 * load that extension until a message is sent to it.
 */
@interface BExecutableExtensionProxy : NSProxy {
	BConfigurationElement *configurationElement;
	NSString *attributeName;
	id delegate;
}

#pragma mark Init

- (id)initWithConfigurationElement:(BConfigurationElement *)aConfigurationElement attributeName:(NSString *)anAttributeName;

@end
