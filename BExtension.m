//
//  BExtension.m
//  Blocks
//
//  Created by Jesse Grosjean on 8/21/07.
//  Copyright 2007 Blocks. All rights reserved.
//

#import "BExtension.h"


@implementation BExtension

#pragma mark Properties

@synthesize plugin;
@synthesize label;
@synthesize extensionPointUniqueIdentifier;

#pragma mark Extensions

@synthesize configurationElements;

- (NSArray *)configurationElementsNamed:(NSString *)name {
	return [[self configurationElements] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name = %@", name]];
}

@end
