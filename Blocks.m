//
//  Blocks.m
//  Blocks
//
//  Created by Jesse Grosjean on 2/21/08.
//  Copyright 2008 Blocks. All rights reserved.
//

#import "Blocks.h"
#import <objc/objc-class.h>


@implementation NSObject (BlocksMethodSwizzle)

// derived from http://rentzsch.com/trac/wiki/JRSwizzle
+ (BOOL)replaceMethod:(SEL)originalSelelector withMethod:(SEL)replacementSelector {
	Method originalMethod = class_getInstanceMethod(self, originalSelelector);	
	if (originalMethod == NULL) {
		BLogError(@"original method %@ not found for class %@", NSStringFromSelector(originalSelelector), [self className]);
		return NO;
	}
	
	Method replacementMethod = class_getInstanceMethod(self, replacementSelector);
	if (replacementMethod == NULL) {
		BLogError(@"original method %@ not found for class %@", NSStringFromSelector(replacementSelector), [self className]);
		return NO;
	}
	
	class_addMethod(self, originalSelelector, class_getMethodImplementation(self, originalSelelector), method_getTypeEncoding(originalMethod));
	class_addMethod(self, replacementSelector, class_getMethodImplementation(self, replacementSelector), method_getTypeEncoding(replacementMethod));	
	method_exchangeImplementations(class_getInstanceMethod(self, originalSelelector), class_getInstanceMethod(self, replacementSelector));
	return YES;
}

@end

// derived from http://www.mikeash.com/svn/MAKVONotificationCenter
@interface BlocksKVONotificationHelper : NSObject {
	id observer;
	SEL selector;
	id userInfo;
	id target;
	NSString *keyPath;
}

- (id)initWithObserver:(id)observer object:(id)target keyPath:(NSString *)keyPath selector:(SEL)selector userInfo:(id)userInfo options: (NSKeyValueObservingOptions)options;
- (void)deregister;

@end

@implementation BlocksKVONotificationHelper

static char BlocksKVONotificationHelperMagicContext;

- (id)initWithObserver:(id)anObserver object:(id)aTarget keyPath:(NSString *)aKeyPath selector:(SEL)aSelector userInfo:(id)aUserInfo options:(NSKeyValueObservingOptions)options {
	if(self = [self init]) {
		observer = anObserver;
		selector = aSelector;
		userInfo = aUserInfo;		
		target = aTarget;
		keyPath = aKeyPath;		
		[target addObserver:self forKeyPath:aKeyPath options:options context:&BlocksKVONotificationHelperMagicContext];
	}
	return self;
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &BlocksKVONotificationHelperMagicContext) {
		// we only ever sign up for one notification per object, so if we got here
		// then we *know* that the key path and object are what we want
		((void (*)(id, SEL, NSString *, id, NSDictionary *, id))objc_msgSend)(observer, selector, aKeyPath, object, change, userInfo);
	} else {
		[super observeValueForKeyPath:aKeyPath ofObject:object change:change context:context];
	}
}

- (void)deregister {
	[target removeObserver:self forKeyPath:keyPath];
}

@end

@interface BlocksKVONotificationCenter : NSObject {
	NSMutableDictionary *observerHelpers;
}
@end

@implementation BlocksKVONotificationCenter

+ (id)defaultCenter {
	static BlocksKVONotificationCenter *defaultCenter = nil;
	if (!defaultCenter) {
		defaultCenter = [[self alloc] init];
//		BlocksKVONotificationCenter *newCenter = [[self alloc] init];
//		OSAtomicCompareAndSwapPtrBarrier(nil, newCenter, (void *)&defaultCenter);
	}
	return defaultCenter;
}

- (id)init {
	if (self = [super init]) {
		observerHelpers = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)dictionaryKeyForObserver:(id)observer object:(id)target keyPath:(NSString *)keyPath selector:(SEL)selector {
	return [NSString stringWithFormat:@"%p:%p:%@:%p", observer, target, keyPath, selector];
}

- (void)addObserver:(id)observer object:(id)target keyPath:(NSString *)keyPath selector:(SEL)selector userInfo:(id)userInfo options: (NSKeyValueObservingOptions)options {
	BlocksKVONotificationHelper *helper = [[BlocksKVONotificationHelper alloc] initWithObserver:observer object:target keyPath:keyPath selector:selector userInfo:userInfo options:options];
	id key = [self dictionaryKeyForObserver:observer object:target keyPath:keyPath selector:selector];
	@synchronized(self) {
		[observerHelpers setObject:helper forKey:key];
	}
}

- (void)removeObserver:(id)observer object:(id)target keyPath:(NSString *)keyPath selector:(SEL)selector {
	id key = [self dictionaryKeyForObserver:observer object:target keyPath:keyPath selector:selector];
	BlocksKVONotificationHelper *helper = nil;
	@synchronized(self) {
		helper = [observerHelpers objectForKey:key];
		[observerHelpers removeObjectForKey:key];
	}
	[helper deregister];
}

@end

@implementation NSObject (BlocksKVONotification)

- (void)addObserver:(id)observer forKeyPath:(NSString *)keyPath selector:(SEL)selector userInfo:(id)userInfo options:(NSKeyValueObservingOptions)options {
	[[BlocksKVONotificationCenter defaultCenter] addObserver:observer object:self keyPath:keyPath selector:selector userInfo:userInfo options:options];
}

- (void)removeObserver:(id)observer keyPath:(NSString *)keyPath selector:(SEL)selector {
	[[BlocksKVONotificationCenter defaultCenter] removeObserver:observer object:self keyPath:keyPath selector:selector];
}

@end

@implementation NSBundle (BlocksMethodReplacements)

+ (void)load {
    if (self == [NSBundle class]) {
		[[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
												[NSNumber numberWithBool:YES], BDisableColorPickersAndInputManagersDefaultsKey, nil]];
		[NSBundle replaceMethod:@selector(initWithPath:) withMethod:@selector(Blocks_initWithPath:)];
    }
}

- (id)Blocks_initWithPath:(NSString *)fullPath {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:BDisableColorPickersAndInputManagersDefaultsKey]) {
		if ([fullPath rangeOfString:@"InputManagers"].location != NSNotFound || [fullPath rangeOfString:@"ColorPickers"].location != NSNotFound) {
			static NSArray *allowedColorPickers = nil;
			if (!allowedColorPickers) {
				allowedColorPickers = [NSArray arrayWithObjects:@"NSColorPickerWheel", @"NSColorPickerUser", @"NSColorPickerSliders", @"NSColorPickerPageableNameList", @"NSColorPickerCrayon", nil];
			}
			
			for (NSString *each in allowedColorPickers) {
				if ([fullPath rangeOfString:each].location != NSNotFound) {
					return [self Blocks_initWithPath:fullPath];
				}
			}
			
			BLogInfo([NSString stringWithFormat:@"Skipping loading of unknown bundles %@", fullPath]);
			
			return nil;
		}
	}
	return [self Blocks_initWithPath:fullPath];
}

@end

NSString *BDisableColorPickersAndInputManagersDefaultsKey = @"BDisableColorPickersAndInputManagersDefaultsKey";