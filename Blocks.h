#import <Cocoa/Cocoa.h>

#import <Blocks/BExtensionRegistry.h>
#import <Blocks/BPlugin.h>
#import <Blocks/BRequirement.h>
#import <Blocks/BExtensionPoint.h>
#import <Blocks/BExtension.h>
#import <Blocks/BConfigurationElement.h>
#import <Blocks/BLog.h>
#import <Blocks/RegexKitLite.h>

// derived from http://rentzsch.com/trac/wiki/JRSwizzle
@interface NSObject (BlocksMethodSwizzle)
+ (BOOL)replaceMethod:(SEL)originalSelelector withMethod:(SEL)replacementSelector;
@end

// derived from http://www.mikeash.com/svn/MAKVONotificationCenter
@interface NSObject (BlocksKVONotification)
- (void)addObserver:(id)observer forKeyPath:(NSString *)keyPath selector:(SEL)selector userInfo:(id)userInfo options:(NSKeyValueObservingOptions)options;
- (void)removeObserver:(id)observer keyPath:(NSString *)keyPath selector:(SEL)selector;
@end

#pragma mark Blocks Macros.

#define BLocalizedString(key, comment) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:nil]
#define BLocalizedStringFromTable(key, tbl, comment) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:(tbl)]
#define BLocalizedStringFromTableInBundle(key, tbl, bundle, comment) [bundle localizedStringForKey:(key) value:@"" table:(tbl)]
#define BLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) [bundle localizedStringForKey:(key) value:(val) table:(tbl)]

APPKIT_EXTERN NSString *BDisableColorPickersAndInputManagersDefaultsKey;
