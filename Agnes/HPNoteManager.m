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
    [self performNoUndoModelUpdateAndSave:YES block:^{
        NSString *text;
        long i = 1;
        NSMutableArray *texts = [NSMutableArray array];
        while ((text = [self stringWithFormat:@"tutorial%ld" index:i]))
        {
            [texts addObject:text];
            i++;
        };            
        for (i = texts.count - 1; i >= 0; i--)
        {
            NSString *text = texts[i];
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

- (NSString*)stringWithFormat:(NSString*)format index:(long)i
{
    NSString *key = [NSString stringWithFormat:format, i];
    NSString *value = NSLocalizedString(key, @"");
    return [value isEqualToString:key] ? nil : value;
}

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
    [self performModelUpdateWithName:@"Archive" save:NO block:^{
        note.archived = YES;
    }];
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
    [self performModelUpdateWithName:actionName save:YES block:^{
        note.text = text;
        note.modifiedAt = [NSDate date];
        if (isNew)
        {
            [self.context insertObject:note];
        }
    }];
}

- (void)reorderNotes:(NSArray*)notes tagName:(NSString*)tagName
{
    [self performModelUpdateWithName:@"Reorder" save:NO block:^{
        NSInteger notesCount = notes.count;
        for (NSInteger i = 0; i < notesCount; i++)
        {
            HPNote *note = notes[i];
            [note setOrder:notesCount - i inTag:tagName];
        }
    } ];
}

- (void)viewNote:(HPNote*)note
{
    [self performNoUndoModelUpdateAndSave:NO block:^{
        note.views++;
    }];
}

- (void)unarchiveNote:(HPNote*)note
{
    [self performModelUpdateWithName:@"Unarchive" save:NO block:^{
        note.archived = NO;
    }];
}

- (void)trashNote:(HPNote*)note
{
    if (note.managedObjectContext == nil) return;
    [self performModelUpdateWithName:@"Delete Note" save:NO block:^{
        [self.context deleteObject:note];
    }];
}

@end
