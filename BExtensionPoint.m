//
//  BExtensionPoint.m
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import "BExtensionPoint.h"
#import "BExtensionRegistry.h"
#import "BExtension.h"
#import "BPlugin.h"
#import "Blocks.h"


@implementation BExtensionPoint

#pragma mark Properties

@synthesize plugin;
@synthesize identifier;

- (NSString *)documentation {
	if (!documentation) {
		documentation = [NSString stringWithContentsOfFile:[self.plugin.bundle pathForResource:self.identifier ofType:@"markdown"]];
		if (!documentation) {
			documentation = BLocalizedString(@"No documentation could be found for this extension point.", nil);
		}
	}
	return documentation;
}

#pragma mark Extensions

- (NSArray *)extensions {
	return [[BExtensionRegistry sharedInstance] extensionsFor:identifier];
}

- (NSArray *)configurationElements {
	return [[BExtensionRegistry sharedInstance] configurationElementsFor:identifier];
}

- (NSArray *)configurationElementsNamed:(NSString *)name {
	return [[[BExtensionRegistry sharedInstance] configurationElementsFor:identifier] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", name]];
}

@end
