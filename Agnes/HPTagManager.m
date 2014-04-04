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
#import "HPTracker.h"
#import <CoreData/CoreData.h>

static NSString *const HPTagInboxName = @"Inbox";
static NSString *const HPTagArchiveName = @"Archive";

@implementation HPTagManager
{
    NDMutableTrie *_tagTrie;
    
    // Cache
    HPTag *_inboxTag;
    HPTag *_archiveTag;
}

#pragma mark HPEntityManager

- (void)didInsertObject:(HPTag*)object
{
    if (!(object.isSystem))
    {
        NSString *normalizedName = object.name.lowercaseString;
        [_tagTrie addString:normalizedName];
    }
    [self removeDuplicatesOfTagNamed:object.name];
}

- (void)didDeleteObject:(HPTag*)object
{
    NSString *normalizedName = object.name.lowercaseString;
    [_tagTrie removeObjectForKey:normalizedName];
    if (object == _inboxTag)
    {
        _inboxTag = nil;
    }
    if (object == _archiveTag)
    {
        _archiveTag = nil;
    }
}

- (void)didInvalidateAllObjects
{
    _inboxTag = nil;
    _archiveTag = nil;
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

#pragma mark System tags

- (HPTag*)archiveTag
{
    if (!_archiveTag)
    {
        _archiveTag = [self systemTagWithName:HPTagArchiveName];
    }
    return _archiveTag;
}

- (HPTag*)inboxTag
{
    if (!_inboxTag)
    {
        _inboxTag = [self systemTagWithName:HPTagInboxName];
    }
    return _inboxTag;
}

#pragma mark Fetching tags

- (NSArray*)indexTags
{
    static NSPredicate *predicate = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        predicate = [NSPredicate predicateWithFormat:@"%K != %@ && %K != %@",
                     NSStringFromSelector(@selector(name)),
                     HPTagInboxName,
                     NSStringFromSelector(@selector(name)),
                     HPTagArchiveName];
    });
    NSArray *indexTags = [self objectsWithPredicate:predicate];
    return indexTags;
}

- (HPTag*)tagWithName:(NSString*)name
{
    HPTag *tag = [self tagForName:name];
    if (!tag)
    {
        tag = [self insertTagWithName:name isSystem:NO];
        [[HPTracker defaultTracker] trackEventWithCategory:@"system" action:@"add_tag" label:name];
    }
    return tag;
}

- (HPTag*)tagForName:(NSString*)name
{
    NSArray *result = [self tagsForName:name];
    HPTag *tag = [result firstObject];
    return tag;
}

- (NSArray*)tagNamesWithPrefix:(NSString*)prefix
{
    if (!_tagTrie)
    {
        _tagTrie = [[NDMutableTrie alloc] initWithCaseInsensitive:YES];
        for (HPTag *tag in self.objects)
        {
            NSString *normalizedName = tag.name.lowercaseString;
            [_tagTrie addString:normalizedName];
        }
        NSString *path = [[NSBundle mainBundle] pathForResource:@"hashtags" ofType:@"plist"];
        NSArray *hashtahgs = [NSArray arrayWithContentsOfFile:path];
        [_tagTrie addArray:hashtahgs];
    }
    NSString *normalizedPrefix = prefix.lowercaseString;
    return [_tagTrie everyObjectForKeyWithPrefix:normalizedPrefix];
}

#pragma mark - Private

- (HPTag*)insertTagWithName:(NSString*)name isSystem:(BOOL)isSystem
{
    HPTag *tag = [HPTag insertNewObjectIntoContext:self.context];
    tag.uuid = [[NSUUID UUID] UUIDString];
    tag.name = name;
    tag.order = CGFLOAT_MAX;
    tag.isSystem = isSystem;
    return tag;
}

- (void)removeDuplicatesOfTagNamed:(NSString*)tagName
{
    NSArray *tags = [self tagsForName:tagName];
    if (tags.count < 2) return;
    
    HPTag *mainTag = [tags firstObject];
    NSArray *duplicateTags = [tags subarrayWithRange:NSMakeRange(1, tags.count - 1)];
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

- (NSArray*)tagsForName:(NSString*)name
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K =[c] %@", NSStringFromSelector(@selector(name)), name];
    fetchRequest.predicate = predicate;
    // In case of duplicate tags always return the same one. This is needed by removeDuplicatesOfTagNamed: and helps reduce conflicts in other cases.
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(uuid)) ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    NSError *error;
    NSArray *result = [self.context executeFetchRequest:fetchRequest error:&error];
    NSAssert(result, @"Fetch %@ failed with error %@", fetchRequest, error);
    return result;
}

- (HPTag*)systemTagWithName:(NSString*)name
{
    HPTag *tag = [self tagForName:name];
    if (!tag)
    {
        tag = [self insertTagWithName:name isSystem:YES];
    }
    return tag;
}

@end

@implementation HPTagManager(Actions)

- (void)archiveNote:(HPNote*)note
{
    [self performModelUpdateWithName:NSLocalizedString(@"Archive", @"") save:YES block:^{
        note.archived = YES;
        
        HPTag *inboxTag = self.inboxTag;
        [inboxTag removeCd_notesObject:note];
        [note removeCd_tagsObject:inboxTag];
        
        HPTag *archiveTag = self.archiveTag;
        [archiveTag addCd_notesObject:note];
        [note addCd_tagsObject:self.archiveTag];
    }];
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

- (void)reorderTags:(NSArray*)tags exchangeObjectAtIndex:(NSUInteger)fromIndex withObjectAtIndex:(NSUInteger)toIndex
{
    if (fromIndex > toIndex)
    {
        NSUInteger aux = fromIndex;
        fromIndex = toIndex;
        toIndex = aux;
    }
    [self performModelUpdateWithName:NSLocalizedString(@"Reorder", @"") save:NO block:^{
        HPTag *fromTag = tags[fromIndex];
        HPTag *toTag = tags[toIndex];
        CGFloat fromOrder = fromTag.order;
        CGFloat toOrder = toTag.order;
        if (fromOrder != toOrder)
        {
            fromTag.order = toOrder;
            toTag.order = fromOrder;
        }
        else
        {
            NSInteger minIndex = fromIndex;
            CGFloat minOrder = fromOrder;
            if (minIndex > 0)
            {
                do
                {
                    minIndex--;
                    HPTag *tag = tags[minIndex];
                    minOrder = tag.order;
                } while (minIndex > 0 && minOrder == toOrder);
            }
            if (minIndex == 0)
            {
                minOrder = CGFLOAT_MIN;
            }
            const CGFloat delta = toOrder - minOrder;
            const CGFloat count = toIndex - minIndex;
            const CGFloat increment = delta / count;
            
            for (NSUInteger i = minIndex; i < toIndex; i++)
            {
                HPTag *tag = tags[i];
                const CGFloat currentOrder = minOrder + increment * (i - minIndex);
                tag.order = currentOrder;
            }
            
            fromOrder = fromTag.order;
            fromTag.order = toOrder;
            toTag.order = fromOrder;
        }
    }];
}

- (void)unarchiveNote:(HPNote*)note
{
    [self performModelUpdateWithName:NSLocalizedString(@"Unarchive", @"") save:YES block:^{
        note.archived = NO;
        
        HPTag *inboxTag = self.inboxTag;
        [inboxTag addCd_notesObject:note];
        [note addCd_tagsObject:inboxTag];
        
        HPTag *archiveTag = self.archiveTag;
        [archiveTag removeCd_notesObject:note];
        [note removeCd_tagsObject:self.archiveTag];
    }];
}

- (void)viewTag:(HPTag*)tag
{
    [self performNoUndoModelUpdateAndSave:NO block:^{
        tag.views++;
        tag.viewedAt = [NSDate date];
    }];
}

@end
