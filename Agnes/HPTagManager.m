//
//  HPTagManager.m
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPTagManager.h"
#import "HPTag.h"
#import "HPAppDelegate.h"
#import "NDTrie.h"
#import <CoreData/CoreData.h>

@implementation HPTagManager
{
    NDMutableTrie *_tagTrie;
}

#pragma mark - HPEntityManager

- (void)didInsertObject:(HPTag*)object
{
    [_tagTrie addString:object.name];
}

- (void)didDeleteObject:(HPTag*)object
{
    [_tagTrie removeObjectForKey:object.name];
}

- (NSString*)entityName
{
    return [HPTag entityName];
}

#pragma mark - Class

+ (HPTagManager*)sharedManager
{
    static HPTagManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HPAppDelegate *appDelegate = (HPAppDelegate*)[UIApplication sharedApplication].delegate;
        instance = [[HPTagManager alloc] initWithManagedObjectContext:appDelegate.managedObjectContext];
    });
    return instance;
}

#pragma mark - Public

- (HPTag*)tagWithName:(NSString*)name
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(name)), name];
    fetchRequest.predicate = predicate;
    NSError *error;
    NSArray *result = [self.context executeFetchRequest:fetchRequest error:&error];
    NSAssert(result, @"Fetch %@ failed with error %@", fetchRequest, error);
    HPTag *tag = [result firstObject];
    if (!tag)
    {
        tag = [HPTag insertNewObjectIntoContext:self.context];
        tag.name = name;
    }
    return tag;
}

- (NSArray*)tagNamesWithPrefix:(NSString*)prefix
{
    if (!_tagTrie)
    {
        _tagTrie = [[NDMutableTrie alloc] initWithCaseInsensitive:YES];
        for (HPTag *tag in self.objects)
        {
            [_tagTrie addString:tag.name];
        }
    }
    return [_tagTrie everyObjectForKeyWithPrefix:prefix];
}

@end
