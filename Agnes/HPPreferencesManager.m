//
//  HPPreferencesManager.m
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPPreferencesManager.h"

NSString *const HPAgnesDefaultsKeyDisplayCriteria = @"HPAgnesDisplayCriteria";
NSString *const HPAgnesDefaultsKeySessionCount = @"HPAgnesSessionCount";

@implementation HPPreferencesManager

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
    return [UIColor colorWithRed:198.0f/255.0f green:67.0f/255.0f blue:252.0f/255.0f alpha:1.0];
}

@end
