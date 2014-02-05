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
#import "HPNote.h"
#import <CoreData/CoreData.h>

@implementation HPTagManager
{
    NDMutableTrie *_tagTrie;
}

#pragma mark - HPEntityManager

- (void)didInsertObject:(HPTag*)object
{
    [_tagTrie addString:object.name];
    [self removeDuplicatesOfTagNamed:object.name];
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
    NSArray *result = [self tagsWithName:name];
    HPTag *tag = [result firstObject];
    if (!tag)
    {
        tag = [HPTag insertNewObjectIntoContext:self.context];
        tag.uuid = [[NSUUID UUID] UUIDString];
        tag.name = name;
        tag.order = NSIntegerMax;
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

- (void)removeDuplicates
{
    [self removeDuplicatesWithUniquePropertyNamed:NSStringFromSelector(@selector(name)) removeBlock:^(id uniqueValue) {
        [self removeDuplicatesOfTagNamed:uniqueValue];
    }];
}

- (void)reorderTagsWithNames:(NSArray*)names
{
    [self performModelUpdateWithName:NSLocalizedString(@"Reorder", @"") save:NO block:^{
        NSInteger count = names.count;
        [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
            HPTag *tag = [self tagWithName:name];
            tag.order = count - idx;
        }];
    }];
}

#pragma mark - Private

- (void)removeDuplicatesOfTagNamed:(NSString*)tagName
{
    NSArray *tags = [self tagsWithName:tagName];
    if (tags.count < 2) return;
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(uuid)) ascending:YES];
    NSArray *sortedTags = [tags sortedArrayUsingDescriptors:@[sortDescriptor]];
    HPTag *mainTag = [sortedTags firstObject];
    NSArray *duplicateTags = [sortedTags subarrayWithRange:NSMakeRange(1, sortedTags.count - 1)];
    for (HPTag *duplicate in duplicateTags)
    {
        NSSet *notes = [NSSet setWithSet:duplicate.cd_notes];
        for (HPNote *note in notes)
        {
            [duplicate removeCd_notesObject:note];
            [note removeCd_tagsObject:duplicate];
            [mainTag addCd_notesObject:note];
            [note addCd_tagsObject:mainTag];
        }
        [self.context deleteObject:duplicate];
    }
}

- (NSArray*)tagsWithName:(NSString*)name
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(name)), name];
    fetchRequest.predicate = predicate;
    NSError *error;
    NSArray *result = [self.context executeFetchRequest:fetchRequest error:&error];
    NSAssert(result, @"Fetch %@ failed with error %@", fetchRequest, error);
    return result;
}

@end
