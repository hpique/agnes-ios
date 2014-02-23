//
//  AGNPreferenceManager.m
//  Agnes
//
//  Created by Hermes on 23/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNPreferenceManager.h"
#import "AGNPreference.h"
#import "HPAppDelegate.h"

static NSString *const AGNPreferenceTutorialNotesAddedKey = @"tutorialNotesAdded";

@implementation AGNPreferenceManager

- (NSString*)entityName
{
    return [AGNPreference entityName];
}

#pragma mark - Class

+ (AGNPreferenceManager*)sharedManager
{
    static AGNPreferenceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HPAppDelegate *appDelegate = (HPAppDelegate*)[UIApplication sharedApplication].delegate;
        instance = [[AGNPreferenceManager alloc] initWithManagedObjectContext:appDelegate.managedObjectContext];
    });
    return instance;
}

#pragma mark Public

- (void)setTutorialNotesAdded:(BOOL)tutorialNotesAdded
{
    NSString *value = [NSString stringWithFormat:@"%d", tutorialNotesAdded];
    [self setPreferenceValue:value forKey:AGNPreferenceTutorialNotesAddedKey];
}

- (BOOL)tutorialNotesAdded
{
    NSString *value = [self preferenceValueForKey:AGNPreferenceTutorialNotesAddedKey];
    return [value boolValue];
}

#pragma mark Private

- (NSString*)preferenceValueForKey:(NSString*)key
{
    AGNPreference *preference = [self preferenceForKey:key];
    return preference.value;
}

- (void)setPreferenceValue:(NSString*)value forKey:(NSString*)key
{
    AGNPreference *preference = [self preferenceForKey:key];
    if (!preference)
    {
        preference = [AGNPreference insertNewObjectIntoContext:self.context];
        preference.key = key;
    }
    preference.value = value;
    [self save];
}

- (AGNPreference*)preferenceForKey:(NSString*)key
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(key)), key];
    NSArray *objects = [self objectsWithPredicate:predicate];
    return objects.firstObject;
}

@end
