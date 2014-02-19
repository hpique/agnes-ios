//
//  HPNoteManager.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteManager.h"
#import "HPTagManager.h"
#import "HPPreferencesManager.h"
#import "HPNote.h"
#import "HPAppDelegate.h"
#import "HPNote.h"
#import "HPTag.h"
#import "HPAttachment.h"
#import "HPAttachment+Template.h"
#import "HPData.h"
#import "HPAgnesImageCache.h"
#import "UIImage+hp_utils.h"
#import <CoreData/CoreData.h>
#import <MobileCoreServices/MobileCoreServices.h>

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
        NSMutableArray *tutorialUUIDs = [NSMutableArray array];
        for (HPNote *note in notes)
        {
            [tutorialUUIDs addObject:note.uuid];
        }
        [HPPreferencesManager sharedManager].tutorialUUIDs = tutorialUUIDs;
    }];
}

- (void)removeLocalTutorialNotes
{
    NSArray *tutorialUUIDs = [HPPreferencesManager sharedManager].tutorialUUIDs;
    for (NSString *uuid in tutorialUUIDs)
    {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", NSStringFromSelector(@selector(uuid)), uuid];
        fetchRequest.predicate = predicate;
        NSError *error;
        NSArray *result = [self.context executeFetchRequest:fetchRequest error:&error];
        NSAssert(result, @"Fetch %@ failed with error %@", fetchRequest, error);
        HPNote *note = [result firstObject];
        if (note)
        {
            [self.context deleteObject:note];
        }
    }
}

#pragma mark System notes

- (BOOL)isSystemNote:(HPNote*)note
{
    return note.managedObjectContext == _systemContext;
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

#pragma mark Sorting notes

+ (NSArray*)sortedNotes:(NSArray*)notes mode:(HPTagSortMode)mode tag:(HPTag*)tag
{
    switch (mode)
    {
        case HPTagSortModeOrder:
        {
            return [notes sortedArrayWithOptions:0 usingComparator:^NSComparisonResult(HPNote *note1, HPNote *note2) {
                CGFloat order1 = [note1 orderInTag:tag.name];
                CGFloat order2 = [note2 orderInTag:tag.name];
                if (order1 < order2) return NSOrderedAscending;
                if (order1 > order2) return NSOrderedDescending;
                return [note2.modifiedAt compare:note1.modifiedAt];
            }];
            break;
        }
        case HPTagSortModeAlphabetical:
        {
            static NSSortDescriptor *sortDescriptor = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(title)) ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
            });
            return [HPNoteManager sortedNotes:notes withDescriptor:sortDescriptor];
            break;
        }
        case HPTagSortModeModifiedAt:
        {
            static NSSortDescriptor *sortDescriptor = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(modifiedAt)) ascending:NO];
            });
            return [HPNoteManager sortedNotes:notes withDescriptor:sortDescriptor];
            break;
        }
        case HPTagSortModeViews:
        {
            static NSSortDescriptor *sortDescriptor = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(views)) ascending:NO];
            });
            return [HPNoteManager sortedNotes:notes withDescriptor:sortDescriptor];
            break;
        }
        case HPTagSortModeTag:
        {
            static NSSortDescriptor *sortDescriptor = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(firstTagName)) ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
            });
            return [HPNoteManager sortedNotes:notes withDescriptor:sortDescriptor];
            break;
        }
    }
}

#pragma mark Blank notes

- (HPNote*)blankNoteWithTag:(HPTag*)tag
{
    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:self.context];
    HPNote *note = [[HPNote alloc] initWithEntity:entityDescription insertIntoManagedObjectContext:nil];
    note.uuid = [[NSUUID UUID] UUIDString];
    note.createdAt = [NSDate date];
    note.modifiedAt = note.createdAt;
    note.detailMode = HPNoteDetailModeModifiedAt;
    note.text = [HPNoteManager textOfBlankNoteWithTag:tag];
    return note;
}

+ (NSString*)textOfBlankNoteWithTag:(HPTag*)tag
{
    if (tag == nil || tag.isSystem)
    {
        return @"";
    }
    return [NSString stringWithFormat:@"\n\n\n\n%@", tag.name];
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
    NSRegularExpression *attachmentRegex = [HPAttachment templateRegex];
    NSMutableArray *notes = [NSMutableArray array];
    for (i = texts.count - 1; i >= 0; i--)
    {
        NSMutableString *mutableText = [texts[i] mutableCopy];
        HPNote *note = [HPNote insertNewObjectIntoContext:context];
        note.uuid = [[NSUUID UUID] UUIDString];
        note.createdAt = [NSDate date];
        note.modifiedAt = note.createdAt;
        note.detailMode = HPNoteDetailModeNone;
        
        NSMutableArray *attachments = [NSMutableArray array];
        NSArray *matches = [attachmentRegex matchesInString:mutableText options:kNilOptions range:NSMakeRange(0, mutableText.length)];
        NSString *resourceDirectory = [NSBundle mainBundle].resourcePath;
        for (NSInteger i = matches.count - 1; i >= 0; i--)
        {
            NSTextCheckingResult *result = matches[i];
            NSString *imageName = [HPAttachment imageNameFromTemplate:mutableText match:result];
            NSString *path = [resourceDirectory stringByAppendingPathComponent:imageName];
            NSData *data = [NSData dataWithContentsOfFile:path];
            if (!data)
            {
                UIImage *image = [UIImage imageNamed:imageName];
                if (!image) continue;
                data = UIImagePNGRepresentation(image);
            }
            HPAttachment *attachment = [HPAttachment attachmentWithData:data type:(NSString*)kUTTypeImage context:context];
            attachment.createdAt = [NSDate date];
            attachment.mode = [HPAttachment modeFromTemplate:mutableText match:result];
            [attachments insertObject:attachment atIndex:0]; // Reverse order
            
            NSRange matchRange = [result rangeAtIndex:0];
            [mutableText replaceCharactersInRange:matchRange withString:[HPNote attachmentString]];
            
            if (attachment.mode == HPAttachmentModeDefault)
            {
                [[HPAgnesImageCache sharedCache] prePopulateCacheWithThumbnailOfImageNamed:imageName atttachment:attachment];
            }
        }
        note.text = mutableText;
        [note replaceAttachments:attachments];
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

+ (NSArray*)sortedNotes:(NSArray*)notes withDescriptor:(NSSortDescriptor*)sortDescriptor
{
    static NSSortDescriptor *modifiedAtSortDescriptor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        modifiedAtSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(modifiedAt)) ascending:NO];
    });
    return [notes sortedArrayUsingDescriptors:@[sortDescriptor, modifiedAtSortDescriptor]];
}

@end

@implementation HPNoteManager(Actions)

- (NSUInteger)attachToNote:(HPNote*)note data:(NSData*)data type:(NSString*)type index:(NSInteger)index
{
    BOOL isNew = note.managedObjectContext == nil;
    NSString *actionName = isNew ? NSLocalizedString(@"Add Note", @"") : NSLocalizedString(@"Attach Image", @"");
    __block NSUInteger attachmentIndex = 0;
    [self performModelUpdateWithName:actionName save:YES block:
     ^{
         if (isNew)
         {
             [self.context insertObject:note];
         }
         HPAttachment *attachment = [HPAttachment attachmentWithData:data type:type context:note.managedObjectContext];
         attachmentIndex = [note addAttachment:attachment atIndex:index];
     }];
    return attachmentIndex;
}

- (void)editNote:(HPNote*)note text:(NSString*)text attachments:(NSArray*)attachments
{
    BOOL isNew = note.managedObjectContext == nil;
    NSString *actionName = isNew ? NSLocalizedString(@"Add Note", @"") : NSLocalizedString(@"Edit Note", @"");
    [self performModelUpdateWithName:actionName save:YES block:^{
        if (isNew)
        {
            [self.context insertObject:note];
        }
        note.text = [NSString stringWithString:text];
        [note replaceAttachments:attachments];
        note.modifiedAt = [NSDate date];
    }];
}

- (void)importNotes:(NSArray*)notes
{
    [self performModelUpdateWithName:NSLocalizedString(@"Import Notes", @"") save:YES block:^{
        for (HPNoteImport *noteImport in notes)
        {
            [noteImport insertNoteInContext:self.context];
        }
    }];
}

- (void)reorderNotes:(NSArray*)notes exchangeObjectAtIndex:(NSUInteger)fromIndex withObjectAtIndex:(NSUInteger)toIndex inTag:(HPTag*)tag
{
    if (fromIndex > toIndex)
    {
        NSUInteger aux = fromIndex;
        fromIndex = toIndex;
        toIndex = aux;
    }
    [self performModelUpdateWithName:NSLocalizedString(@"Reorder", @"") save:NO block:^{
        HPNote *fromNote = notes[fromIndex];
        HPNote *toNote = notes[toIndex];
        NSString *tagName = tag.name;
        CGFloat fromOrder = [fromNote orderInTag:tagName];
        CGFloat toOrder = [toNote orderInTag:tagName];
        if (fromOrder != toOrder)
        {
            [fromNote setOrder:toOrder inTag:tagName];
            [toNote setOrder:fromOrder inTag:tagName];
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
                    HPNote *note = notes[minIndex];
                    minOrder = [note orderInTag:tagName];
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
                HPNote *note = notes[i];
                const CGFloat currentOrder = minOrder + increment * (i - minIndex);
                [note setOrder:currentOrder inTag:tagName];
            }
            
            CGFloat fromOrder = [fromNote orderInTag:tagName];
            [fromNote setOrder:toOrder inTag:tagName];
            [toNote setOrder:fromOrder inTag:tagName];
        }
    }];
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

- (void)trashNote:(HPNote*)note
{
    if (note.managedObjectContext == nil) return;
    [self performModelUpdateWithName:NSLocalizedString(@"Delete Note", @"") save:YES block:^{
        [self.context deleteObject:note];
    }];
}

@end

@implementation HPNoteImport

+ (HPNoteImport*)noteImportWithText:(NSString*)text createdAt:(NSDate*)createdAt modifiedAt:(NSDate*)modifiedAt attachments:(NSArray*)attachments
{
    HPNoteImport *noteImport = [[HPNoteImport alloc] init];
    noteImport.text = text;
    noteImport.createdAt = createdAt;
    noteImport.modifiedAt = modifiedAt;
    noteImport.attachments = attachments;
    return noteImport;
}

- (HPNote*)insertNoteInContext:(NSManagedObjectContext*)context
{
    HPNote *note = [HPNote insertNewObjectIntoContext:context];
    note.uuid = [[NSUUID UUID] UUIDString];
    note.createdAt = self.createdAt;
    note.modifiedAt = self.modifiedAt;
    note.text = self.text;
    for (HPAttachment *attachment in self.attachments)
    {
        [context insertObject:attachment.data];
        [context insertObject:attachment];
    }
    [note replaceAttachments:self.attachments];
    return note;
}

@end
