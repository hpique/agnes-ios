//
//  HPNoteManager.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteManager.h"
#import "HPNote.h"

static void *HPNoteManagerContext = &HPNoteManagerContext;

@implementation HPNoteManager {
    NSMutableArray *_notes;
    NSMutableDictionary *_tags;
}

- (id) init
{
    if (self = [super init])
    {
        _notes = [NSMutableArray array];
        _tags = [NSMutableDictionary dictionary];
        [self addTutorialNotes];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == HPNoteManagerContext)
    {
        [self updateTagsWithNote:object];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Public

- (NSArray*)notes
{
    return [NSArray arrayWithArray:_notes];
}

- (void)addNote:(HPNote *)note
{
    [_notes addObject:note];
    for (NSString *tag in note.tags)
    {
        [self addNote:note forTag:tag];
    }
    [note addObserver:self forKeyPath:NSStringFromSelector(@selector(text)) options:NSKeyValueObservingOptionNew context:HPNoteManagerContext];
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
    [note removeObserver:self forKeyPath:NSStringFromSelector(@selector(text))];
    for (NSString *tag in note.tags)
    {
        [self removeNote:note forTag:tag];
    }
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

#pragma mark - Private

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

- (void)addNote:(HPNote*)note forTag:(NSString*)tag
{
    NSMutableSet *notes = [_tags objectForKey:tag];
    if (!notes)
    {
        notes = [NSMutableSet set];
        [_tags setObject:notes forKey:tag];
    };
    [notes addObject:note];
}

- (void)removeNote:(HPNote*)note forTag:(NSString*)tag
{
    NSMutableSet *notes = [_tags objectForKey:tag];
    if (!notes) return;
    [notes removeObject:note];
    if (notes.count == 0)
    {
        [_tags removeObjectForKey:tag];
    }
}

- (void)updateTagsWithNote:(HPNote*)note
{
    for (NSString *tag in note.removedTags)
    {
        [self removeNote:note forTag:tag];
    }
    for (NSString *tag in note.addedTags)
    {
        [self addNote:note forTag:tag];
    }
}

@end
