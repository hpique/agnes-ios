//
//  HPPreferencesManager.m
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPPreferencesManager.h"
#import "ColorUtils.h"

NSString *const HPPreferencesManagerDidChangePreferencesNotification = @"HPPreferencesManagerDidChangePreferencesNotification";

NSString *const HPAgnesDefaultsKeyDisplayCriteria = @"HPAgnesDisplayCriteria";
NSString *const HPAgnesDefaultsKeySessionCount = @"HPAgnesSessionCount";
NSString *const HPAgnesDefaultsKeyTintColor = @"HPAgnesTintColor";
NSString *const HPAgnesDefaultsKeyBarTintColor = @"HPAgnesBarTintColor";
NSString *const HPAgnesPreferencesKeyTintColor = @"tintColor";
NSString *const HPAgnesPreferencesKeyBarTintColor = @"barTintColor";
NSString *const HPAgnesPreferencesValueDefault = @"default";

static UIColor* HPAgnesDefaultTintColor = nil;
static UIColor* HPAgnesDefaultBarTintColor = nil;

@implementation HPPreferencesManager

+ (void)initialize
{
    HPAgnesDefaultTintColor = [UIColor colorWithRed:198.0f/255.0f green:67.0f/255.0f blue:252.0f/255.0f alpha:1.0];
    HPAgnesDefaultBarTintColor = [UIColor colorWithRed:200.0f/255.0f green:110.0f/255.0f blue:223.0f/255.0f alpha:1.0];
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

- (HPNoteDisplayCriteria)displayCriteriaForListTitle:(NSString*)title default:(HPNoteDisplayCriteria)defaultDisplayCriteria
{
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:HPAgnesDefaultsKeyDisplayCriteria];
    id value = [dictionary objectForKey:title];
    return value ? [value integerValue] : defaultDisplayCriteria;
}

- (void)setDisplayCriteria:(HPNoteDisplayCriteria)displayCriteria forListTitle:(NSString*)title
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [userDefaults objectForKey:HPAgnesDefaultsKeyDisplayCriteria];
    NSMutableDictionary *updatedDictionary = dictionary ? [NSMutableDictionary dictionaryWithDictionary:dictionary] : [NSMutableDictionary dictionary];
    [updatedDictionary setObject:@(displayCriteria) forKey:title];
    [userDefaults setObject:updatedDictionary forKey:HPAgnesDefaultsKeyDisplayCriteria];
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

- (UIColor*)tintColor
{
    return [self colorForKey:HPAgnesDefaultsKeyTintColor defaultColor:HPAgnesDefaultTintColor];
}

- (NSString*)tintColorName
{
    UIColor *color = self.tintColor;
    return [color isEquivalentToColor:HPAgnesDefaultTintColor] ? HPAgnesPreferencesValueDefault : [color stringValue];
}

- (void)setBarTintColor:(UIColor *)barTintColor
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *colorString = [barTintColor stringValue];
    [userDefaults setValue:colorString forKey:HPAgnesDefaultsKeyBarTintColor];
    [UINavigationBar appearance].barTintColor = barTintColor;
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

- (UIColor*)barTintColor
{
    return [self colorForKey:HPAgnesDefaultsKeyBarTintColor defaultColor:HPAgnesDefaultBarTintColor];
}

- (NSString*)barTintColorName
{
    UIColor *color = self.barTintColor;
    return [color isEquivalentToColor:HPAgnesDefaultBarTintColor] ? HPAgnesPreferencesValueDefault : [color stringValue];
}

- (void)applyPreferences:(NSString*)preferences
{
    static NSRegularExpression *preferenceLineRegex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* pattern = @"(\\w+)=(\\w+)";
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
        UIColor *color = [value isEqualToString:HPAgnesPreferencesValueDefault] ? HPAgnesDefaultTintColor : [UIColor colorWithString:value];
        if (!color) return;
        if ([self.tintColor isEquivalentToColor:color]) return;
        self.tintColor = color;
    }
    else if ([key isEqualToString:HPAgnesPreferencesKeyBarTintColor])
    {
        UIColor *color = [value isEqualToString:HPAgnesPreferencesValueDefault] ? HPAgnesDefaultBarTintColor : [UIColor colorWithString:value];
        if (!color) return;
        if ([self.barTintColor isEquivalentToColor:color]) return;
        self.barTintColor = color;
    }
}

@end
