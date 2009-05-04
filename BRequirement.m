//
//  BRequirement.m
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import "BRequirement.h"
#import "BExtensionRegistry.h"
#import "BPlugin.h"
#import "Blocks.h"


@interface BExtensionRegistry (BRequirementPrivate)
- (BPlugin *)pluginFor:(NSString *)pluginID;
@end

@implementation BRequirement

#pragma mark Properties

@synthesize plugin;
@synthesize optional;
@synthesize version;
@synthesize requiredBundleIdentifier;

- (id)requiredBundle {
	BPlugin *requiredLoadableObject = [[BExtensionRegistry sharedInstance] pluginFor:[self requiredBundleIdentifier]];
	if (requiredLoadableObject) return requiredLoadableObject;
	return [NSBundle bundleWithIdentifier:[self requiredBundleIdentifier]];
}

#pragma mark Loading

- (BOOL)isLoaded {
	return [[self requiredBundle] isLoaded];
}

- (BOOL)loadAndReturnError:(NSError **)error {
	NSString *errorDescription = nil;
	
	id requiredBundle = [self requiredBundle];
	
	if (!requiredBundle) {
		errorDescription = [NSString stringWithFormat:BLocalizedString(@"The \"%@\" plugin could not be loaded because its \"%@\" requirement could not be found.", nil), plugin.label, [requiredBundleIdentifier pathExtension]];
	} else {
		NSArray *actualVersionComponents = [[requiredBundle version] componentsSeparatedByString:@"."];
		NSArray *versionComponents = [version componentsSeparatedByString:@"."];

		if (![[actualVersionComponents objectAtIndex:0] isEqualToString:[versionComponents objectAtIndex:0]] || [[actualVersionComponents objectAtIndex:0] intValue] < [[versionComponents objectAtIndex:0] intValue]) {
			errorDescription = [NSString stringWithFormat:BLocalizedString(@"The \"%@\" plugin could not be loaded because it requires version %@ of \"%@\", but only version %@ is availible.", nil), plugin.label, version, [requiredBundle label], [requiredBundle version]];
		}
	}
	
	if (errorDescription && error != NULL) {
		*error = [NSError errorWithDomain:@"BlocksErrorDomain" code:0 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:errorDescription, NSLocalizedDescriptionKey, nil]];		
		return NO;
	}
	
	if ([requiredBundle loadAndReturnError:error]) {
		return YES;
	} else {
		return NO;
	}
}

@end
