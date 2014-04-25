//
//  AGNPreferencesManager.m
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNPreferencesManager.h"
#import "HPFontManager.h"
#import "UIColor+hp_utils.h"
#import "UIImage+hp_utils.h"
#import <iOS7Colors/UIColor+iOS7Colors.h>
#import <ColorUtils/ColorUtils.h>

NSString *const AGNPreferencesManagerDidChangePreferencesNotification = @"AGNPreferencesManagerDidChangePreferencesNotification";

static NSString *const AGNDefaultsKeyBarTintColor = @"HPAgnesBarTintColor";
static NSString *const AGNDefaultsKeyDynamicType = @"HPAgnesDynamicType";
static NSString *const AGNDefaultsKeyFontName = @"HPAgnesFontName";
static NSString *const AGNDefaultsKeyFontSize = @"HPAgnesFontSize";
static NSString *const AGNDefaultsKeyIndexSortMode = @"HPIndexSortMode";
static NSString *const AGNDefaultsKeyLastViewedTag = @"AGNLastViewedTag";
static NSString *const AGNDefaultsKeyListSeparatorsHidden = @"AGNListSeparatorsHidden";
static NSString *const AGNDefaultsKeyStatusBarHidden = @"HPAgnesStatusBarHidden";
static NSString *const AGNDefaultsKeyTintColor = @"HPAgnesTintColor";

static NSString *const AGNPreferencesKeyBarTintColor = @"barTintColor";
static NSString *const AGNPreferencesKeyBarTintColorGB = @"barTintColour";
static NSString *const AGNPreferencesKeyDynamicType = @"dynamicType";
static NSString *const AGNPreferencesKeyFontName = @"fontName";
static NSString *const AGNPreferencesKeyFontSize = @"fontSize";
static NSString *const AGNPreferencesKeyListSeparatorsHidden = @"listSeparatorsHidden";
static NSString *const AGNPreferencesKeyStatusBarHidden = @"statusBarHidden";
static NSString *const AGNPreferencesKeyTintColor = @"tintColor";
static NSString *const AGNPreferencesKeyTintColorGB = @"tintColour";
static NSString *const AGNPreferencesValueDefault = @"default";

static UIColor* AGNDefaultBarTintColor = nil;
static BOOL const AGNDefaultDynamicType = NO;
static NSString* const AGNDefaultFontName = @"AvenirNext-Regular";
static NSInteger const AGNDefaultFontSizePhone = 16;
static NSInteger const AGNDefaultFontSizePad = 18;
static NSInteger const AGNDefaultIndexSortMode = HPIndexSortModeOrder;
static BOOL AGNDefaultListSeparatorsHidden = NO;
static BOOL AGNDefaultStatusBarHidden = NO;
static UIColor* AGNDefaultTintColor = nil;
static CGFloat const AGNLuminanceMiddle = 0.6;

@implementation AGNPreferencesManager

+ (void)initialize
{
    AGNDefaultTintColor = [UIColor colorWithRed:198.0f/255.0f green:67.0f/255.0f blue:252.0f/255.0f alpha:1.0];
    AGNDefaultBarTintColor = [UIColor colorWithRed:200.0f/255.0f green:110.0f/255.0f blue:223.0f/255.0f alpha:1.0];
    AGNDefaultStatusBarHidden = [UIScreen mainScreen].bounds.size.height < 568.0;

    [UIColor registerColor:[UIColor iOS7lightBlueColor] forName:@"lightBlue"];
    [UIColor registerColor:[UIColor iOS7lightGrayColor] forName:@"lightGray"];
    [UIColor registerColor:[UIColor iOS7darkBlueColor] forName:@"blue"];
    [UIColor registerColor:[UIColor iOS7darkGrayColor] forName:@"gray"];
    [UIColor registerColor:[UIColor iOS7greenColor] forName:@"green"];
    [UIColor registerColor:[UIColor iOS7orangeColor] forName:@"orange"];
    [UIColor registerColor:[UIColor iOS7pinkColor] forName:@"pink"];
    [UIColor registerColor:[UIColor iOS7purpleColor] forName:@"purple"];
    [UIColor registerColor:[UIColor iOS7redColor] forName:@"red"];
    [UIColor registerColor:AGNDefaultBarTintColor forName:@"violet"];
    [UIColor registerColor:[UIColor iOS7yellowColor] forName:@"yellow"];
}

+ (AGNPreferencesManager*)sharedManager
{
    static AGNPreferencesManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AGNPreferencesManager alloc] init];
    });
    return instance;
}

- (UIColor*)barForegroundColor
{
    UIColor *barTintColor = self.barTintColor;
    const CGFloat luminance = [barTintColor hp_luminance];
    if (luminance > AGNLuminanceMiddle) return [UIColor darkGrayColor];
    return [UIColor whiteColor];
}

- (UIColor*)barTintColor
{
    return [self colorForKey:AGNDefaultsKeyBarTintColor defaultColor:AGNDefaultBarTintColor];
}

- (NSString*)barTintColorName
{
    return [self.barTintColor stringValue];
}

- (BOOL)dynamicType
{
    return [self boolValueForKey:AGNDefaultsKeyDynamicType default:AGNDefaultDynamicType];
}

- (NSString*)fontName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *fontName = [userDefaults objectForKey:AGNDefaultsKeyFontName];
    return fontName ? : AGNDefaultFontName;
}

- (NSInteger)fontSize
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *fontSize = [userDefaults objectForKey:AGNDefaultsKeyFontSize];
    return fontSize ? [fontSize integerValue] : [self.class defaultFontSize];
}

- (void)setFontName:(NSString *)fontName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:fontName forKey:AGNDefaultsKeyFontName];
    [HPFontManager sharedManager].fontName = fontName;
    [self styleNavigationBar:[UINavigationBar appearance]];
    [[NSNotificationCenter defaultCenter] postNotificationName:AGNPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setFontSize:(NSInteger)fontSize
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(fontSize) forKey:AGNDefaultsKeyFontSize];
    [HPFontManager sharedManager].fontSize = fontSize;
    [[NSNotificationCenter defaultCenter] postNotificationName:AGNPreferencesManagerDidChangePreferencesNotification object:self];
}

- (HPIndexSortMode)indexSortMode
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *value = [userDefaults valueForKey:AGNDefaultsKeyIndexSortMode];
    return value ? [value integerValue] : AGNDefaultIndexSortMode;
}

- (NSString*)lastViewedTagName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults valueForKey:AGNDefaultsKeyLastViewedTag];
}

- (void)setBarTintColor:(UIColor *)barTintColor
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *colorString = [barTintColor stringValue];
    [userDefaults setValue:colorString forKey:AGNDefaultsKeyBarTintColor];
    [self styleStatusBar];
    [self styleSearchBar];
    [self styleNavigationBar:[UINavigationBar appearance]];
    [[NSNotificationCenter defaultCenter] postNotificationName:AGNPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setDynamicType:(BOOL)dynamicType
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(dynamicType) forKey:AGNDefaultsKeyDynamicType];
    [HPFontManager sharedManager].dinamicType = dynamicType;
    [[NSNotificationCenter defaultCenter] postNotificationName:AGNPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setIndexSortMode:(HPIndexSortMode)indexSortMode
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(indexSortMode) forKey:AGNDefaultsKeyIndexSortMode];
}

- (void)setLastViewedTagName:(NSString *)lastViewedTagName
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:lastViewedTagName forKey:AGNDefaultsKeyLastViewedTag];
}

- (void)setListSeparatorsHidden:(BOOL)listSeparatorsHidden
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(listSeparatorsHidden) forKey:AGNDefaultsKeyListSeparatorsHidden];
    [[NSNotificationCenter defaultCenter] postNotificationName:AGNPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(statusBarHidden) forKey:AGNDefaultsKeyStatusBarHidden];
    [UIApplication sharedApplication].statusBarHidden = statusBarHidden;
    [[NSNotificationCenter defaultCenter] postNotificationName:AGNPreferencesManagerDidChangePreferencesNotification object:self];
}

- (void)setTintColor:(UIColor *)tintColor
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *colorString = [tintColor stringValue];
    [userDefaults setValue:colorString forKey:AGNDefaultsKeyTintColor];
    [UIApplication sharedApplication].keyWindow.tintColor = self.tintColor;
    [[NSNotificationCenter defaultCenter] postNotificationName:AGNPreferencesManagerDidChangePreferencesNotification object:self];
}

- (BOOL)listSeparatorsHidden
{
    return [self boolValueForKey:AGNDefaultsKeyListSeparatorsHidden default:AGNDefaultListSeparatorsHidden];
}

- (BOOL)statusBarHidden
{
    return [self boolValueForKey:AGNDefaultsKeyStatusBarHidden default:AGNDefaultStatusBarHidden];
}

- (UIStatusBarStyle)statusBarStyle
{
    const CGFloat luminance = [self.barTintColor hp_luminance];
    const UIStatusBarStyle statusBarStyle = luminance > AGNLuminanceMiddle ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
    return statusBarStyle;
}

- (UIColor*)tintColor
{
    return [self colorForKey:AGNDefaultsKeyTintColor defaultColor:AGNDefaultTintColor];
}

- (NSString*)tintColorName
{
    return [self.tintColor stringValue];
}

- (void)applyPreferences:(NSString*)preferences
{
    static NSRegularExpression *preferenceLineRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* pattern = @"(\\w+)=([\\w#-]+)";
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

- (void)styleNavigationBar:(UINavigationBar*)navigationBar
{
    navigationBar.barTintColor = self.barTintColor;
    UIColor *barForegroundColor = self.barForegroundColor;
    navigationBar.tintColor = barForegroundColor;
    HPFontManager *fontManager = [HPFontManager sharedManager];
    navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName : barForegroundColor, NSFontAttributeName : fontManager.fontForNavigationBarTitle};
    NSDictionary *barButtontitleTextAttributes = @{ NSFontAttributeName : fontManager.fontForBarButtonTitle};
    [[UIBarButtonItem appearance] setTitleTextAttributes:barButtontitleTextAttributes forState:UIControlStateNormal];
    // TODO: Fix MFMailComposeViewController buttons. See: http://stackoverflow.com/questions/19736481/how-do-i-make-the-color-of-uibarbuttonitems-for-mfmailcomposeviewcontroller-from
    // TODO: Update current back button. Don't know how to access it.
}

- (void)styleSearchBar
{
    UIColor* barTintColor = [AGNPreferencesManager sharedManager].barTintColor;
    barTintColor = [barTintColor colorBlendedWithColor:[UIColor whiteColor] factor:0.1]; // Blend with white to compensate bar translucency
    UIImage *backgroundImage = [UIImage hp_imageWithColor:barTintColor size:CGSizeMake(1, 1)];
    [[UISearchBar appearance] setBackgroundImage:backgroundImage forBarPosition:UIBarPositionTopAttached barMetrics:UIBarMetricsDefault];
}

- (void)styleStatusBar
{
    [UIApplication sharedApplication].statusBarHidden = self.statusBarHidden;
    [UIApplication sharedApplication].statusBarStyle = self.statusBarStyle;
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

+ (CGFloat)defaultFontSize
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? AGNDefaultFontSizePhone : AGNDefaultFontSizePad;
}

- (void)setPreferenceValue:(NSString*)value forKey:(NSString*)key
{
    if ([key isEqualToString:AGNPreferencesKeyTintColor] || [key isEqualToString:AGNPreferencesKeyTintColorGB])
    {
        [self updateTintColorFromValue:value];
    }
    else if ([key isEqualToString:AGNPreferencesKeyBarTintColor] || [key isEqualToString:AGNPreferencesKeyBarTintColorGB])
    {
        [self updateBarTintColorFromValue:value];
    }
    else if ([key isEqualToString:AGNPreferencesKeyListSeparatorsHidden])
    {
        [self updateListSeparatorsHiddenFromValue:value];
    }
    else if ([key isEqualToString:AGNPreferencesKeyStatusBarHidden])
    {
        [self updateStatusBarHiddenFromValue:value];
    }
    else if ([key isEqualToString:AGNPreferencesKeyDynamicType])
    {
        [self updateDynamicTypeFromValue:value];
    }
    else if ([key isEqualToString:AGNPreferencesKeyFontName])
    {
        [self updateFontNameFromValue:value];
    }
    else if ([key isEqualToString:AGNPreferencesKeyFontSize])
    {
        [self updateFontSizeFromValue:value];
    }
}

- (void)updateBarTintColorFromValue:(NSString*)value
{
    UIColor *color = [value isEqualToString:AGNPreferencesValueDefault] ? AGNDefaultBarTintColor : [UIColor colorWithString:value];
    if (!color) return;
    if ([self.barTintColor isEquivalentToColor:color]) return;
    self.barTintColor = color;
}

- (void)updateDynamicTypeFromValue:(NSString*)value
{
    BOOL boolValue = [value isEqualToString:AGNPreferencesValueDefault] ? AGNDefaultDynamicType : [value boolValue];
    if (self.dynamicType == boolValue) return;
    self.dynamicType = boolValue;
}

- (void)updateFontNameFromValue:(NSString*)value
{
    NSString *fontName = [value isEqualToString:AGNPreferencesValueDefault] ? AGNDefaultFontName : value;
    fontName = fontName.lowercaseString;
    if (![fontName isEqualToString:HPFontManagerSystemFontName])
    {
        UIFont *font = [UIFont fontWithName:fontName size:10];
        if (!font) return;
        NSString *resultFontName = font.fontName;
        if (![resultFontName.lowercaseString hasPrefix:fontName]) return;
        fontName = resultFontName;
    }
    self.fontName = fontName;
}

- (void)updateFontSizeFromValue:(NSString*)value
{
    NSInteger fontSize = [value isEqualToString:AGNPreferencesValueDefault] ? [self.class defaultFontSize] : [value integerValue];
    if (self.fontSize == fontSize) return;
    self.fontSize = MIN(MAX(8, fontSize), 28); // Prevent app from becoming unusable
}

- (void)updateListSeparatorsHiddenFromValue:(NSString*)value
{
    BOOL boolValue = [value isEqualToString:AGNPreferencesValueDefault] ? AGNDefaultListSeparatorsHidden : [value boolValue];
    if (self.listSeparatorsHidden == boolValue) return;
    self.listSeparatorsHidden = boolValue;
}

- (void)updateStatusBarHiddenFromValue:(NSString*)value
{
    BOOL boolValue = [value isEqualToString:AGNPreferencesValueDefault] ? AGNDefaultStatusBarHidden : [value boolValue];
    if (self.statusBarHidden == boolValue) return;
    self.statusBarHidden = boolValue;
}

- (void)updateTintColorFromValue:(NSString*)value
{
    UIColor *color = [value isEqualToString:AGNPreferencesValueDefault] ? AGNDefaultTintColor : [UIColor colorWithString:value];
    if (!color) return;
    if ([self.tintColor isEquivalentToColor:color]) return;
    self.tintColor = color;
}

@end
