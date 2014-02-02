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
#import "HPAttachment.h"
#import "HPData.h"
#import "UIImage+hp_utils.h"
#import <CoreData/CoreData.h>

static void *HPNoteManagerContext = &HPNoteManagerContext;

@implementation HPNoteManager {
    NSArray *_systemNotes;
    NSManagedObjectContext *_systemContext;
}

- (id) initWithManagedObjectContext:(NSManagedObjectContext *)context
{
    if (self = [super initWithManagedObjectContext:context])
    {
        _systemContext = [[NSManagedObjectContext alloc] init];
        _systemContext.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:context.persistentStoreCoordinator.managedObjectModel];
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
        NSArray *notes = [self notesWithKeyFormat:@"tutorial%ld" context:self.context];
        for (HPNote *note in notes)
        {
            if ([note.text rangeOfString:[HPNote attachmentString]].location != NSNotFound)
            {
                UIImage *image = [UIImage imageNamed:@"sample.jpg"];
                HPAttachment *attachment = [HPAttachment attachmentWithImage:image context:note.managedObjectContext];
                [note hp_addAttachmentsObject:attachment];
                break;
            }
        }
    }];
}

- (NSArray*)systemNotes
{
    if (!_systemNotes)
    {
        _systemNotes = [self notesWithKeyFormat:@"system%d" context:_systemContext];
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

+ (NSArray*)sortedNotes:(NSArray*)notes mode:(HPTagSortMode)mode tag:(HPTag*)tag
{
    NSSortDescriptor *sortDescriptor;
    switch (mode)
    {
        case HPTagSortModeOrder:
        {
            return [notes sortedArrayWithOptions:0 usingComparator:^NSComparisonResult(HPNote *note1, HPNote *note2) {
                NSInteger order1 = [note1 orderInTag:tag.name];
                NSInteger order2 = [note2 orderInTag:tag.name];
                if (order2 < order1) return NSOrderedAscending;
                if (order2 > order1) return NSOrderedDescending;
                return [note2.modifiedAt compare:note1.modifiedAt];
            }];
        }
            break;
        case HPTagSortModeAlphabetical:
            return [HPNoteManager sortedNotes:notes selector:@selector(title) ascending:YES];
            break;
        case HPTagSortModeModifiedAt:
            return [HPNoteManager sortedNotes:notes selector:@selector(modifiedAt) ascending:NO];
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(modifiedAt)) ascending:NO];
            break;
        case HPTagSortModeViews:
            return [HPNoteManager sortedNotes:notes selector:@selector(views) ascending:NO];
            break;
    }
}

#pragma mark - Private

- (NSArray*)notesWithKeyFormat:(NSString*)keyFormat context:(NSManagedObjectContext*)context
{
    NSString *text;
    long i = 1;
    NSMutableArray *texts = [NSMutableArray array];
    while ((text = [self stringWithFormat:keyFormat index:i]))
    {
        [texts addObject:text];
        i++;
    };
    NSMutableArray *notes = [NSMutableArray array];
    for (i = texts.count - 1; i >= 0; i--)
    {
        NSString *text = texts[i];
        HPNote *note = [HPNote insertNewObjectIntoContext:context];
        note.createdAt = [NSDate date];
        note.modifiedAt = note.createdAt;
        note.detailMode = HPNoteDetailModeNone;
        note.text = text;
        [notes addObject:note];
    }
    return notes;
}

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
    [self performModelUpdateWithName:NSLocalizedString(@"Archive", @"") save:NO block:^{
        note.archived = YES;
    }];
}

- (void)attachToNote:(HPNote*)note image:(UIImage*)image index:(NSInteger)index
{
    BOOL isNew = note.managedObjectContext == nil;
    NSString *actionName = isNew ? NSLocalizedString(@"Add Note", @"") : NSLocalizedString(@"Attach Image", @"");
    [self performModelUpdateWithName:actionName save:YES block:
     ^{
         if (isNew)
         {
             [self.context insertObject:note];
         }
         HPAttachment *attachment = [HPAttachment attachmentWithImage:image context:note.managedObjectContext];
         [note addAttachment:attachment atIndex:index];
     }];
}

- (HPNote*)blankNoteWithTagOfName:(NSString*)tag
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.context];
    HPNote *note = [[HPNote alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:nil];
    note.createdAt = [NSDate date];
    note.modifiedAt = note.createdAt;
    note.detailMode = HPNoteDetailModeModifiedAt;
    note.text = tag ? [NSString stringWithFormat:@"\n\n\n\n%@", tag] : @"";
    return note;
}

- (void)editNote:(HPNote*)note text:(NSString*)text attachments:(NSOrderedSet*)attachments
{
    BOOL isNew = note.managedObjectContext == nil;
    NSString *actionName = isNew ? NSLocalizedString(@"Add Note", @"") : NSLocalizedString(@"Edit Note", @"");
    [self performModelUpdateWithName:actionName save:YES block:^{
        if (isNew)
        {
            [self.context insertObject:note];
        }
        note.text = [NSString stringWithString:text];
        [note hp_removeAttachments:note.attachments];
        [note hp_addAttachments:attachments];
        note.modifiedAt = [NSDate date];
    }];
}

- (void)importNoteWithText:(NSString*)text createdAt:(NSDate*)createdAt modifiedAt:(NSDate*)modifiedAt attachments:(NSArray*)attachments
{
    [self performModelUpdateWithName:NSLocalizedString(@"Import Note", @"") save:YES block:^{
        HPNote *note = [HPNote insertNewObjectIntoContext:self.context];
        note.createdAt = createdAt;
        note.inboxOrder = NSIntegerMax;
        note.modifiedAt = modifiedAt;
        note.text = text;
        for (HPAttachment *attachment in attachments)
        {
            [self.context insertObject:attachment.data];
            [self.context insertObject:attachment.thumbnailData];
            [self.context insertObject:attachment];
        }
        NSOrderedSet *attachmentSet = [NSOrderedSet orderedSetWithArray:attachments];
        [note hp_addAttachments:attachmentSet];
    }];
}

- (void)reorderNotes:(NSArray*)notes tagName:(NSString*)tagName
{
    [self performModelUpdateWithName:NSLocalizedString(@"Reorder", @"") save:NO block:^{
        NSInteger notesCount = notes.count;
        for (NSInteger i = 0; i < notesCount; i++)
        {
            HPNote *note = notes[i];
            [note setOrder:notesCount - i inTag:tagName];
        }
    } ];
}

- (void)setDetailMode:(HPNoteDetailMode)detailMode ofNote:(HPNote*)note
{
    [self performNoUndoModelUpdateAndSave:NO block:^{
        note.detailMode = detailMode;
    }];
}

- (void)viewNote:(HPNote*)note
{
    [self performNoUndoModelUpdateAndSave:NO block:^{
        note.views++;
    }];
}

- (void)unarchiveNote:(HPNote*)note
{
    [self performModelUpdateWithName:NSLocalizedString(@"Unarchive", @"") save:NO block:^{
        note.archived = NO;
    }];
}

- (void)trashNote:(HPNote*)note
{
    if (note.managedObjectContext == nil) return;
    [self performModelUpdateWithName:NSLocalizedString(@"Delete Note", @"") save:NO block:^{
        [self.context deleteObject:note];
    }];
}

@end
