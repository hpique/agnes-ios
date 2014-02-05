//
//  HPPreferencesManager.m
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPPreferencesManager.h"
#import "HPFontManager.h"
#import "ColorUtils.h"

NSString *const HPPreferencesManagerDidChangePreferencesNotification = @"HPPreferencesManagerDidChangePreferencesNotification";

NSString *const HPAgnesDefaultsKeyBarTintColor = @"HPAgnesBarTintColor";
NSString *const HPAgnesDefaultsKeyDynamicType = @"HPAgnesDynamicType";
NSString *const HPAgnesDefaultsKeyFontName = @"HPAgnesFontName";
NSString *const HPAgnesDefaultsKeyFontSize = @"HPAgnesFontSize";
NSString *const HPAgnesDefaultsKeySessionCount = @"HPAgnesSessionCount";
NSString *const HPAgnesDefaultsKeySortMode = @"HPAgnesSortMode";
NSString *const HPAgnesDefaultsKeyStatusBarHidden = @"HPAgnesStatusBarHidden";
NSString *const HPAgnesDefaultsKeyTintColor = @"HPAgnesTintColor";
NSString *const HPAgnesDefaultsKeyTutorialUUIDs = @"HPAgnesTutorialUUIDs";
NSString *const HPAgnesDefaultsKeyTypingSpeed = @"HPAgnesTypingSpeed";

NSString *const HPAgnesPreferencesKeyStatusBarHidden = @"statusBarHidden";
NSString *const HPAgnesPreferencesKeyBarTintColor = @"barTintColor";
NSString *const HPAgnesPreferencesKeyDynamicType = @"dynamicType";
NSString *const HPAgnesPreferencesKeyFontName = @"fontName";
NSString *const HPAgnesPreferencesKeyFontSize = @"fontSize";
NSString *const HPAgnesPreferencesKeyTintColor = @"tintColor";
NSString *const HPAgnesPreferencesValueDefault = @"default";

static UIColor* HPAgnesDefaultBarTintColor = nil;
static BOOL HPAgnesDefaultDynamicType = NO;
static NSString* HPAgnesDefaultFontName = @"System";
static NSInteger HPAgnesDefaultFontSize = 16;
static UIColor* HPAgnesDefaultTintColor = nil;
static BOOL HPAgnesDefaultStatusBarHidden = NO;
static NSTimeInterval HPAgnesDefaultTypingSpeed = 0.5;

@implementation HPPreferencesManager

+ (void)initialize
{
    HPAgnesDefaultTintColor = [UIColor colorWithRed:198.0f/255.0f green:67.0f/255.0f blue:252.0f/255.0f alpha:1.0];
    HPAgnesDefaultBarTintColor = [UIColor colorWithRed:200.0f/255.0f green:110.0f/255.0f blue:223.0f/255.0f alpha:1.0];
    HPAgnesDefaultStatusBarHidden = [UIScreen mainScreen].bounds.size.height < 568.0;
}

+ (HPPreferencesManager*)sharedManager
{
    static HPPreferencesManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPPreferencesManager alloc] init];
    });
    return instance;
}

- (UIColor*)barTintColor
{
    return [self colorForKey:HPAgnesDefaultsKeyBarTintColor defaultColor:HPAgnesDefaultBarTintColor];
}

- (NSString*)barTintColorName
{
    return [self.barTintColor stringValue];
}

- (BOOL)dynamicType
{
    return [self boolValueForKey:HPAgnesDefaultsKeyDynamicType default:HPAgnesDefaultDynamicType];
}

- (NSString*)fontName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *fontName = [userDefaults objectForKey:HPAgnesDefaultsKeyFontName];
    return fontName ? : HPAgnesDefaultFontName;
}

- (NSInteger)fontSize
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *fontSize = [userDefaults objectForKey:HPAgnesDefaultsKeyFontSize];
    return fontSize ? [fontSize integerValue] : HPAgnesDefaultFontSize;
}

- (void)setFontName:(NSString *)fontName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:fontName forKey:HPAgnesDefaultsKeyFontName];
    [HPFontManager sharedManager].fontName = fontName;
    [[NSNotificationCenter defaultCenter] postNotificationName:HPPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setFontSize:(NSInteger)fontSize
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(fontSize) forKey:HPAgnesDefaultsKeyFontSize];
    [HPFontManager sharedManager].fontSize = fontSize;
    [[NSNotificationCenter defaultCenter] postNotificationName:HPPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setSortMode:(HPTagSortMode)mode forListTitle:(NSString*)title
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [userDefaults objectForKey:HPAgnesDefaultsKeySortMode];
    NSMutableDictionary *updatedDictionary = dictionary ? [NSMutableDictionary dictionaryWithDictionary:dictionary] : [NSMutableDictionary dictionary];
    [updatedDictionary setObject:@(mode) forKey:title];
    [userDefaults setObject:updatedDictionary forKey:HPAgnesDefaultsKeySortMode];
}

- (NSInteger)increaseSessionCount
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *value = [userDefaults objectForKey:HPAgnesDefaultsKeySessionCount];
    NSNumber *updatedValue = @([value integerValue] + 1);
    [userDefaults setObject:updatedValue forKey:HPAgnesDefaultsKeySessionCount];
    [userDefaults synchronize];
    return [updatedValue integerValue];
}

- (NSInteger)sessionCount
{
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:HPAgnesDefaultsKeySessionCount];
    return [value integerValue];
}

- (void)setBarTintColor:(UIColor *)barTintColor
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *colorString = [barTintColor stringValue];
    [userDefaults setValue:colorString forKey:HPAgnesDefaultsKeyBarTintColor];
    [UINavigationBar appearance].barTintColor = barTintColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:HPPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setDynamicType:(BOOL)dynamicType
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(dynamicType) forKey:HPAgnesDefaultsKeyDynamicType];
    [HPFontManager sharedManager].dinamicType = dynamicType;
    [[NSNotificationCenter defaultCenter] postNotificationName:HPPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(statusBarHidden) forKey:HPAgnesDefaultsKeyStatusBarHidden];
    [UIApplication sharedApplication].statusBarHidden = statusBarHidden;
    [[NSNotificationCenter defaultCenter] postNotificationName:HPPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setTintColor:(UIColor *)tintColor
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *colorString = [tintColor stringValue];
    [userDefaults setValue:colorString forKey:HPAgnesDefaultsKeyTintColor];
    [UIApplication sharedApplication].keyWindow.tintColor = tintColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:HPPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setTutorialUUIDs:(NSArray *)tutorialUUIDs
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:tutorialUUIDs forKey:HPAgnesDefaultsKeyTutorialUUIDs];
}

- (void)setTypingSpeed:(NSTimeInterval)typingSpeed
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(typingSpeed) forKey:HPAgnesDefaultsKeyTypingSpeed];
}

- (HPTagSortMode)sortModeForListTitle:(NSString*)title default:(HPTagSortMode)defaultSortMode
{
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:HPAgnesDefaultsKeySortMode];
    id value = [dictionary objectForKey:title];
    return value ? [value integerValue] : defaultSortMode;
}

- (BOOL)statusBarHidden
{
    return [self boolValueForKey:HPAgnesDefaultsKeyStatusBarHidden default:HPAgnesDefaultStatusBarHidden];
}

- (UIColor*)tintColor
{
    return [self colorForKey:HPAgnesDefaultsKeyTintColor defaultColor:HPAgnesDefaultTintColor];
}

- (NSString*)tintColorName
{
    return [self.tintColor stringValue];
}

- (NSArray*)tutorialUUIDs
{
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:HPAgnesDefaultsKeySortMode];
    return [dictionary objectForKey:HPAgnesDefaultsKeyTutorialUUIDs];
}

- (NSTimeInterval)typingSpeed
{
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:HPAgnesDefaultsKeyTypingSpeed];
    return value ? [value doubleValue] : HPAgnesDefaultTypingSpeed;
}

- (void)applyPreferences:(NSString*)preferences
{
    static NSRegularExpression *preferenceLineRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* pattern = @"(\\w+)=([\\w#]+)";
        preferenceLineRegex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    });
    [preferenceLineRegex enumerateMatchesInString:preferences options:0 range:NSMakeRange(0, preferences.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange keyRange = [result rangeAtIndex:1];
        NSString *key = [preferences substringWithRange:keyRange];
        NSRange valueRange = [result rangeAtIndex:2];
        NSString *value = [preferences substringWithRange:valueRange];
        [self setPreferenceValue:value forKey:key];
    }];
}

#pragma mark - Private

- (BOOL)boolValueForKey:(NSString*)key default:(BOOL)defaultValue
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *value = [userDefaults valueForKey:key];
    return value ? [value boolValue] : defaultValue;
}

- (UIColor*)colorForKey:(NSString*)key defaultColor:(UIColor*)defaultColor
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *colorString = [userDefaults objectForKey:key];
    UIColor *color;
    if (colorString)
    {
        color = [UIColor colorWithString:colorString];
    }
    return color ? : defaultColor;
}

- (void)setPreferenceValue:(NSString*)value forKey:(NSString*)key
{
    if ([key isEqualToString:HPAgnesPreferencesKeyTintColor])
    {
        [self updateTintColorFromValue:value];
    }
    else if ([key isEqualToString:HPAgnesPreferencesKeyBarTintColor])
    {
        [self updateBarTintColorFromValue:value];
    }
    else if ([key isEqualToString:HPAgnesPreferencesKeyStatusBarHidden])
    {
        [self updateStatusBarHiddenFromValue:value];
    }
    else if ([key isEqualToString:HPAgnesPreferencesKeyDynamicType])
    {
        [self updateDynamicTypeFromValue:value];
    }
    else if ([key isEqualToString:HPAgnesPreferencesKeyFontName])
    {
        [self updateFontNameFromValue:value];
    }
    else if ([key isEqualToString:HPAgnesPreferencesKeyFontSize])
    {
        [self updateFontSizeFromValue:value];
    }
}

- (void)updateBarTintColorFromValue:(NSString*)value
{
    UIColor *color = [value isEqualToString:HPAgnesPreferencesValueDefault] ? HPAgnesDefaultBarTintColor : [UIColor colorWithString:value];
    if (!color) return;
    if ([self.barTintColor isEquivalentToColor:color]) return;
    self.barTintColor = color;
}

- (void)updateDynamicTypeFromValue:(NSString*)value
{
    BOOL boolValue = [value isEqualToString:HPAgnesPreferencesValueDefault] ? HPAgnesDefaultDynamicType : [value boolValue];
    if (self.dynamicType == boolValue) return;
    self.dynamicType = boolValue;
}

- (void)updateFontNameFromValue:(NSString*)value
{
    NSString *fontName = [value isEqualToString:HPAgnesPreferencesValueDefault] ? HPAgnesDefaultFontName : value;
    UIFont *font = [UIFont fontWithName:fontName size:10];
    if (!font) return;
    if ([self.fontName isEqualToString:fontName]) return;
    self.fontName = fontName;
}

- (void)updateFontSizeFromValue:(NSString*)value
{
    NSInteger fontSize = [value isEqualToString:HPAgnesPreferencesValueDefault] ? HPAgnesDefaultFontSize : [value integerValue];
    if (self.fontSize == fontSize) return;
    self.fontSize = MIN(MAX(8, fontSize), 28); // Prevent app from becoming unusable
}

- (void)updateStatusBarHiddenFromValue:(NSString*)value
{
    BOOL boolValue = [value isEqualToString:HPAgnesPreferencesValueDefault] ? HPAgnesDefaultStatusBarHidden : [value boolValue];
    if (self.statusBarHidden == boolValue) return;
    self.statusBarHidden = boolValue;
}

- (void)updateTintColorFromValue:(NSString*)value
{
    UIColor *color = [value isEqualToString:HPAgnesPreferencesValueDefault] ? HPAgnesDefaultTintColor : [UIColor colorWithString:value];
    if (!color) return;
    if ([self.tintColor isEquivalentToColor:color]) return;
    self.tintColor = color;
}

@end
