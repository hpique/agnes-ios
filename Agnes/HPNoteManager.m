//
//  HPNoteManager.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteManager.h"
#import "HPNote.h"
#import "NDTrie.h"
#import "HPAppDelegate.h"
#import "HPNote.h"
#import "HPTag.h"
#import <CoreData/CoreData.h>

static void *HPNoteManagerContext = &HPNoteManagerContext;
NSString* const HPNoteManagerDidUpdateNotesNotification = @"HPNoteManagerDidUpdateNotesNotification";
NSString* const HPNoteManagerDidUpdateTagsNotification = @"HPNoteManagerDidUpdateTagsNotification";

@implementation HPNoteManager {
    NDMutableTrie *_tagTrie;
    NSArray *_systemNotes;
    NSManagedObjectContext *_context;
    NSManagedObjectContext *_systemContext;
}

- (id) init
{
    if (self = [super init])
    {
        HPAppDelegate *appDelegate = (HPAppDelegate*)[UIApplication sharedApplication].delegate;
        _context = appDelegate.managedObjectContext;
        _systemContext = [[NSManagedObjectContext alloc] init];
        _systemContext.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:appDelegate.managedObjectModel];
        _tagTrie = [NDMutableTrie trie];
        [self addTutorialNotes];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == HPNoteManagerContext)
    {
//        [self updateTagsOfNote:object];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Public

- (NSArray*)notes
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Note"];
    NSError *error;
    NSArray *result = [_context executeFetchRequest:fetchRequest error:&error];
    return result;
}

- (NSArray*)notesWithTag:(NSString*)tag
{
    static NSFetchRequest *noteFetchRequest;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        noteFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%@ LIKE %@", NSStringFromSelector(@selector(name)), tag];
        noteFetchRequest.predicate = predicate;
    });
    NSError *error;
    NSArray *result = [_context executeFetchRequest:noteFetchRequest error:&error];
    NSAssert(result, @"Fetch %@ failed with error %@", noteFetchRequest, error);
    HPTag *tagObject = [result firstObject];
    return tag ? [tagObject.notes allObjects] : [NSArray array];
}

- (void)removeNote:(HPNote*)note
{
    [_context deleteObject:note];
    [self save];
}

- (NSArray*)systemNotes
{
    if (!_systemNotes)
    {
        NSMutableArray *notes = [NSMutableArray array];
        for (NSInteger i = 3; i >= 1; i--)
        {
            NSString *key = [NSString stringWithFormat:@"system%d", i];
            NSString *text = NSLocalizedString(key, @"");
            HPNote *note = [HPNote insertNewObjectIntoContext:_systemContext];
            note.createdAt = [NSDate date];
            note.modifiedAt = note.createdAt;
            note.text = text;
            [notes addObject:note];
        }
        _systemNotes = notes;
    }
    return _systemNotes;
}

- (NSArray*)tags
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Tag"];
    NSError *error;
    NSArray *result = [_context executeFetchRequest:fetchRequest error:&error];
    NSAssert(result, @"Fetch %@ failed with error %@", fetchRequest, error);
    return result;
}

- (NSArray*)tagNamesWithPrefix:(NSString*)prefix
{
    return [_tagTrie everyObjectForKeyWithPrefix:prefix];
}

- (HPNote*)note
{
    HPNote *note = [HPNote insertNewObjectIntoContext:_context];
    note.createdAt = [NSDate date];
    note.modifiedAt = note.createdAt;
    return note;
}

- (HPNote*)blankNoteWithTag:(NSString*)tag
{
    HPNote *note = [self note];
    if (tag)
    {
        note.text = [NSString stringWithFormat:@"\n\n\n\n%@", tag];
    }
    return note;
}


#pragma mark - Class

+ (HPNoteManager*)sharedManager
{
    static HPNoteManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPNoteManager alloc] init];
    });
    return instance;
}

+ (NSArray*)sortedNotes:(NSArray*)notes criteria:(HPNoteDisplayCriteria)criteria tag:(NSString*)tag
{
    NSSortDescriptor *sortDescriptor;
    switch (criteria)
    {
        case HPNoteDisplayCriteriaOrder:
        {
            return [notes sortedArrayWithOptions:0 usingComparator:^NSComparisonResult(HPNote *note1, HPNote *note2) {
                NSInteger order1 = [note1 orderInTag:tag];
                NSInteger order2 = [note2 orderInTag:tag];
                if (order2 < order1) return NSOrderedAscending;
                if (order2 > order1) return NSOrderedDescending;
                return [note2.modifiedAt compare:note1.modifiedAt];
            }];
        }
            break;
        case HPNoteDisplayCriteriaAlphabetical:
            return [HPNoteManager sortedNotes:notes selector:@selector(title) ascending:YES];
            break;
        case HPNoteDisplayCriteriaModifiedAt:
            return [HPNoteManager sortedNotes:notes selector:@selector(modifiedAt) ascending:NO];
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(modifiedAt)) ascending:NO];
            break;
        case HPNoteDisplayCriteriaViews:
            return [HPNoteManager sortedNotes:notes selector:@selector(cd_views) ascending:NO];
            break;
    }
}

#pragma mark - Private

- (void)addTutorialNotes
{
    for (NSInteger i = 3; i >= 1; i--)
    {
        NSString *key = [NSString stringWithFormat:@"tutorial%d", i];
        NSString *text = NSLocalizedString(key, @"");
        HPNote *note = [self note];
        note.text = text;
    }
    [self save];
}

//- (void)addTagsOfNote:(HPNote*)note
//{
//    BOOL updated = NO;
//    for (NSString *tag in note.tags)
//    {
//        updated |= [self addNote:note forTag:tag];
//    }
//    if (updated)
//    {
//        [[NSNotificationCenter defaultCenter] postNotificationName:HPNoteManagerDidUpdateTagsNotification object:self];
//    }
//}
//
//- (BOOL)addNote:(HPNote*)note forTag:(NSString*)tag
//{
//    BOOL updated = NO;
//    NSMutableSet *notes = [_tags objectForKey:tag];
//    if (!notes)
//    {
//        notes = [NSMutableSet set];
//        [_tags setObject:notes forKey:tag];
//        [_tagTrie addString:tag];
//        updated = YES;
//    };
//    [notes addObject:note];
//    return updated;
//}

//- (void)removeTagsOfNote:(HPNote*)note
//{
//    BOOL updated = NO;
//    for (NSString *tag in note.tags)
//    {
//        updated |= [self removeNote:note forTag:tag];
//    }
//    if (updated)
//    {
//        [[NSNotificationCenter defaultCenter] postNotificationName:HPNoteManagerDidUpdateTagsNotification object:self];
//    }
//}

//- (BOOL)removeNote:(HPNote*)note forTag:(NSString*)tag
//{
//    BOOL updated = NO;
//    NSMutableSet *notes = [_tags objectForKey:tag];
//    if (notes)
//    {
//        [notes removeObject:note];
//        if (notes.count == 0)
//        {
//            [_tags removeObjectForKey:tag];
//            [_tagTrie removeObjectForKey:tag];
//            updated = YES;
//        }
//    }
//    return YES;
//}

+ (NSArray*)sortedNotes:(NSArray*)notes selector:(SEL)selector ascending:(BOOL)ascending
{
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(selector) ascending:ascending];
    static NSSortDescriptor *modifiedAtSortDescriptor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        modifiedAtSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(modifiedAt)) ascending:NO];
    });
    return [notes sortedArrayUsingDescriptors:@[sortDescriptor, modifiedAtSortDescriptor]];
}

//- (void)updateTagsOfNote:(HPNote*)note
//{
//    BOOL updated = NO;
//    for (NSString *tag in note.removedTags)
//    {
//        updated |= [self removeNote:note forTag:tag];
//    }
//    for (NSString *tag in note.addedTags)
//    {
//        updated |= [self addNote:note forTag:tag];
//    }
//    if (updated)
//    {
//        [[NSNotificationCenter defaultCenter] postNotificationName:HPNoteManagerDidUpdateTagsNotification object:self];
//    }
//}

- (void)save
{
    NSError *error;
    if (![_context save:&error])
    {
        NSLog(@"Whoops, couldn't save: %@", error.localizedDescription);
    }
}

@end
