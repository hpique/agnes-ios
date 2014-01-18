//
//  HPNoteManager.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteManager.h"
#import "HPNote.h"

@implementation HPNoteManager {
    NSMutableArray *_notes;
}

- (id) init
{
    if (self = [super init])
    {
        _notes = [NSMutableArray array];
        [self addTutorialNotes];
    }
    return self;
}

- (NSArray*)notes
{
    return [NSArray arrayWithArray:_notes];
}

- (void)addNote:(HPNote *)note
{
    [_notes addObject:note];
}

- (HPNote*)blankNote
{
    HPNote *note = [HPNote note];
    note.order = self.nextOrder;
    [_notes addObject:note];
    return note;
}

- (NSInteger)nextOrder
{
    __block NSInteger maxOrder = 0;
    [_notes enumerateObjectsUsingBlock:^(HPNote *note, NSUInteger idx, BOOL *stop)
    {
        if (note.order > maxOrder)
        {
            maxOrder = note.order;
        }
    }];
    return maxOrder + 1;
}

- (void)removeNote:(HPNote*)note
{
    [_notes removeObject:note];
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

+ (NSArray*)sortedNotes:(NSArray*)notes criteria:(HPNoteDisplayCriteria)criteria;
{
    NSSortDescriptor *sortDescriptor;
    switch (criteria)
    {
        case HPNoteDisplayCriteriaOrder:
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(order)) ascending:NO];
            break;
        case HPNoteDisplayCriteriaAlphabetical:
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(title)) ascending:YES];
            break;
        case HPNoteDisplayCriteriaModifiedAt:
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(modifiedAt)) ascending:NO];
            break;
        case HPNoteDisplayCriteriaViews:
            sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(views)) ascending:NO];
            break;
    }
    NSSortDescriptor *modifiedAtSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(modifiedAt)) ascending:NO];
    return [notes sortedArrayUsingDescriptors:@[sortDescriptor, modifiedAtSortDescriptor]];
}

- (void)addTutorialNotes
{
    for (NSInteger i = 3; i >= 1; i--)
    {
        NSString *key = [NSString stringWithFormat:@"tutorial%d", i];
        NSString *text = NSLocalizedString(key, @"");
        HPNote *note = [HPNote noteWithText:text];
        [self addNote:note];
    }
}

@end
