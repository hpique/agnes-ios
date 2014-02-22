//
//  HPModelContextImporter.m
//  Agnes
//
//  Created by Hermes on 21/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPModelContextImporter.h"
#import "HPNote.h"
#import "HPAttachment.h"
#import "HPData.h"
#import "HPNoteManager.h"

@implementation HPModelContextImporter {
    NSArray *_noteAttributes;
    NSArray *_attachmentAttributes;
    NSArray *_dataAttributes;
    
    NSManagedObjectContext *_fromContext;
    NSManagedObjectContext *_toContext;
    
    HPNoteManager *_toManager;
}

- (void)importNotesAtContext:(NSManagedObjectContext*)fromContext intoContext:(NSManagedObjectContext*)toContext
{
    _fromContext = fromContext;
    _toContext = toContext;
    __block NSArray *notes;
    [fromContext performBlockAndWait:^{
        HPNoteManager *fromManager = [[HPNoteManager alloc] initWithManagedObjectContext:fromContext];
        notes = fromManager.allObjectsAndAttributes;
        
        NSEntityDescription *noteDescription = [NSEntityDescription entityForName:[HPNote entityName] inManagedObjectContext:fromContext];
        _noteAttributes = [noteDescription attributesByName].allKeys;
        
        NSEntityDescription *attachmentDescription = [NSEntityDescription entityForName:[HPAttachment entityName] inManagedObjectContext:fromContext];
        _attachmentAttributes = [attachmentDescription attributesByName].allKeys;
        
        NSEntityDescription *dataDescription = [NSEntityDescription entityForName:[HPData entityName] inManagedObjectContext:fromContext];
        _dataAttributes = [dataDescription attributesByName].allKeys;
    }];
    [toContext performBlockAndWait:^{
        _toManager = [[HPNoteManager alloc] initWithManagedObjectContext:toContext];
        for (HPNote *note in notes)
        {
            @autoreleasepool
            {
                if ([self findOrDeleteDuplicateOfNote:note]) continue;
                [self importNote:note];
            }
        }
    }];
}

#pragma mark Private

- (BOOL)findOrDeleteDuplicateOfNote:(HPNote*)note
{
    NSDate *existingModifiedAt = nil;
    __block NSString *noteUUID;
    [_fromContext performBlockAndWait:^{
        noteUUID = note.uuid;
    }];
    HPNote *existingNote = [_toManager noteForUUID:noteUUID];
    if (existingNote)
    {
        existingModifiedAt = existingNote.modifiedAt;
    }
    
    if (existingModifiedAt)
    {
        if ([existingModifiedAt laterDate:note.modifiedAt] == existingModifiedAt)
        { // Existing note is fresher
            return YES;
        }
        else
        {
            [_toContext deleteObject:existingNote];
        }
    }
    return NO;
}

- (void)importNote:(HPNote*)note
{
    NSMutableSet *attachments = [NSMutableSet set];
    for (HPAttachment *attachment in note.attachments)
    {
        __block NSDictionary *attachmentValues;
        [_fromContext performBlockAndWait:^{
            attachmentValues = [attachment dictionaryWithValuesForKeys:_attachmentAttributes];
        }];
        HPAttachment *attachmentCopy = [HPAttachment insertNewObjectIntoContext:_toContext];
        [attachmentCopy setValuesForKeysWithDictionary:attachmentValues];
        [attachments addObject:attachmentCopy];
        
        if (attachment.data)
        {
            __block NSDictionary *dataValues;
            [_fromContext performBlockAndWait:^{
                dataValues = [attachment.data dictionaryWithValuesForKeys:_dataAttributes];
            }];
            HPData *dataCopy = [HPData insertNewObjectIntoContext:_toContext];
            [dataCopy setValuesForKeysWithDictionary:dataValues];
            attachmentCopy.data = dataCopy;
        }
    }
    __block NSDictionary *noteValues;
    [_fromContext performBlockAndWait:^{
        noteValues = [note dictionaryWithValuesForKeys:_noteAttributes];
    }];
    HPNote *noteCopy = [HPNote insertNewObjectIntoContext:_toContext];
    [noteCopy setValuesForKeysWithDictionary:noteValues];
    [noteCopy setCd_attachments:attachments];
}

@end
