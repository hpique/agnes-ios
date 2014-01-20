//
//  HPPreferencesManager.m
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPPreferencesManager.h"

NSString *const HPAgnesUserDefaultsKeyDisplayCriteria = @"HPAgnesDisplayCriteria";
NSString *const HPAgnesUserDefaultsKeyNoninitialRun = @"HPAgnesNoninitialRun";

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
    NSDictionary *dictionary = [[NSUserDefaults standardUserDefaults] objectForKey:HPAgnesUserDefaultsKeyDisplayCriteria];
    id value = [dictionary objectForKey:title];
    return value ? [value integerValue] : defaultDisplayCriteria;
}

- (void)setDisplayCriteria:(HPNoteDisplayCriteria)displayCriteria forListTitle:(NSString*)title
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *dictionary = [userDefaults objectForKey:HPAgnesUserDefaultsKeyDisplayCriteria];
    NSMutableDictionary *updatedDictionary = dictionary ? [NSMutableDictionary dictionaryWithDictionary:dictionary] : [NSMutableDictionary dictionary];
    [updatedDictionary setObject:@(displayCriteria) forKey:title];
    [userDefaults setObject:updatedDictionary forKey:HPAgnesUserDefaultsKeyDisplayCriteria];
}

- (void)setNoninitialRun
{
    [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:HPAgnesUserDefaultsKeyNoninitialRun];
}

- (BOOL)isNoninitialRun
{
    NSNumber *object = [[NSUserDefaults standardUserDefaults] objectForKey:HPAgnesUserDefaultsKeyNoninitialRun];
    return [object boolValue];
}

@end
