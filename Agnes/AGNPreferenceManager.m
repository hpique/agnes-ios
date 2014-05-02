//
//  AGNPreferenceManager.m
//  Agnes
//
//  Created by Hermes on 23/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNPreferenceManager.h"
#import "AGNPreference.h"
#import "AGNAppDelegate.h"

static NSString *const AGNPreferenceTutorialNotesAddedKey = @"tutorialNotesAdded";

@implementation AGNPreferenceManager

- (NSString*)entityName
{
    return [AGNPreference entityName];
}

#pragma mark Class

+ (AGNPreferenceManager*)sharedManager
{
    static AGNPreferenceManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AGNAppDelegate *appDelegate = (AGNAppDelegate*)[UIApplication sharedApplication].delegate;
        instance = [[AGNPreferenceManager alloc] initWithManagedObjectContext:appDelegate.managedObjectContext];
    });
    return instance;
}

#pragma mark HPEntityManager

- (void)didInsertObject:(AGNPreference*)preference
{
    [self performNoUndoModelUpdateAndSave:YES block:^
    {
        NSString *key = preference.key;
        [self removeDuplicatesWithKey:key];
    }];
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

- (void)removeDuplicates
{
    [self performNoUndoModelUpdateAndSave:YES block:^
    {
        [self removeDuplicatesWithUniquePropertyNamed:NSStringFromSelector(@selector(key)) removeBlock:^(NSString *key)
        {
            [self removeDuplicatesWithKey:key];
        }];
    }];
}

#pragma mark Private

- (NSString*)preferenceValueForKey:(NSString*)key
{
    AGNPreference *preference = [self preferenceForKey:key];
    return preference.value;
}

- (void)setPreferenceValue:(NSString*)value forKey:(NSString*)key
{
    [self performNoUndoModelUpdateAndSave:YES block:^{
        AGNPreference *preference = [self preferenceForKey:key];
        if (!preference)
        {
            preference = [AGNPreference insertNewObjectIntoContext:self.context];
            preference.key = key;
        }
        preference.value = value;
    }];
}

- (AGNPreference*)preferenceForKey:(NSString*)key
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(key)), key];
    NSArray *objects = [self objectsWithPredicate:predicate];
    return objects.firstObject;
}

- (void)removeDuplicatesWithKey:(NSString*)key
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(key)), key];
    NSArray *preferences = [self objectsWithPredicate:predicate];
    if (preferences.count < 2) return;
    
    // TODO: Use date to remove duplicates
    NSArray *duplicates = [preferences subarrayWithRange:NSMakeRange(1, preferences.count - 1)];
    for (NSManagedObject *preference in duplicates)
    {
        [self.context deleteObject:preference];
    }
}

@end
