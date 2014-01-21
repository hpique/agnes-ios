//
//  HPNoteManager.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteManager.h"
#import "HPNote.h"
#import "HPAppDelegate.h"
#import "HPNote.h"
#import "HPTag.h"
#import <CoreData/CoreData.h>

static void *HPNoteManagerContext = &HPNoteManagerContext;

@implementation HPNoteManager {
    NSArray *_systemNotes;
    NSManagedObjectContext *_systemContext;
    NSManagedObjectContext *_tempContext;
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    if (self = [super initWithManagedObjectContext:context])
    {
        _systemContext = [[NSManagedObjectContext alloc] init];
        _systemContext.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:context.persistentStoreCoordinator.managedObjectModel];
        _tempContext = [[NSManagedObjectContext alloc] init];
        _tempContext.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:context.persistentStoreCoordinator.managedObjectModel];
    }
    return self;
}

- (NSString*)entityName
{
    return [HPNote entityName];
}

#pragma mark - Public

- (void)addTutorialNotes
{
    [self performNoUndoModelUpdateBlock:^{
        for (int i = 4; i >= 1; i--)
        {
            NSString *key = [NSString stringWithFormat:@"tutorial%d", i];
            NSString *text = NSLocalizedString(key, @"");
            HPNote *note = [HPNote insertNewObjectIntoContext:self.context];
            note.createdAt = [NSDate date];
            note.modifiedAt = note.createdAt;
            note.text = text;
        }
    }];
}

- (NSArray*)systemNotes
{
    if (!_systemNotes)
    {
        NSMutableArray *notes = [NSMutableArray array];
        for (int i = 1; i >= 1; i--)
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

#pragma mark - Class

+ (HPNoteManager*)sharedManager
{
    static HPNoteManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        HPAppDelegate *appDelegate = (HPAppDelegate*)[UIApplication sharedApplication].delegate;
        instance = [[HPNoteManager alloc] initWithManagedObjectContext:appDelegate.managedObjectContext];
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
            return [HPNoteManager sortedNotes:notes selector:@selector(views) ascending:NO];
            break;
    }
}

#pragma mark - Private

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

@end

@implementation HPNoteManager(Actions)

- (void)archiveNote:(HPNote*)note
{
    [self performModelUpdateBlock:^{
        note.archived = YES;
    } actionName:@"Archive Note"];
}

- (HPNote*)blankNoteWithTag:(NSString*)tag
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.context];
    HPNote *note = [[HPNote alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:nil];
    note.createdAt = [NSDate date];
    note.modifiedAt = note.createdAt;
    note.text = tag ? [NSString stringWithFormat:@"\n\n\n\n%@", tag] : @"";
    return note;
}

- (void)editNote:(HPNote*)note text:(NSString*)text;
{
    BOOL isNew = note.managedObjectContext == nil;
    NSString *actionName = isNew ? @"Add Note" : @"Edit Note";
    [self performModelUpdateBlock:^{
        note.text = text;
        note.modifiedAt = [NSDate date];
        if (isNew)
        {
            [self.context insertObject:note];
        }
    } actionName:actionName];
}

- (void)viewNote:(HPNote*)note
{
    [self performNoUndoModelUpdateBlock:^{
        note.views++;
    }];
}

- (void)unarchiveNote:(HPNote*)note
{
    [self performModelUpdateBlock:^{
        note.archived = NO;
    } actionName:@"Unarchive Note"];
}

- (void)trashNote:(HPNote*)note
{
    if (note.managedObjectContext == nil) return;
    [self performModelUpdateBlock:^{
        [self.context deleteObject:note];
    } actionName:@"Delete Note"];
}

@end
