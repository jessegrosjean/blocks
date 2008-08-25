#import <Cocoa/Cocoa.h>

#import <Blocks/BExtensionRegistry.h>
#import <Blocks/BPlugin.h>
#import <Blocks/BRequirement.h>
#import <Blocks/BExtensionPoint.h>
#import <Blocks/BExtension.h>
#import <Blocks/BConfigurationElement.h>
#import <Blocks/BLog.h>

#pragma mark Localization macros useful in executable extension classes.

#define BLocalizedString(key, comment) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:nil]
#define BLocalizedStringFromTable(key, tbl, comment) [[NSBundle bundleForClass:[self class]] localizedStringForKey:(key) value:@"" table:(tbl)]
#define BLocalizedStringFromTableInBundle(key, tbl, bundle, comment) [bundle localizedStringForKey:(key) value:@"" table:(tbl)]
#define BLocalizedStringWithDefaultValue(key, tbl, bundle, val, comment) [bundle localizedStringForKey:(key) value:(val) table:(tbl)]

@interface NSObject (BlocksMethodSwizzle)
+ (BOOL)replaceMethod:(SEL)originalSelelector withMethod:(SEL)replacementSelector;
@end
