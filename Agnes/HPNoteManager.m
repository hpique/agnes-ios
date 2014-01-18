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
NSString* const HPNoteManagerDidUpdateTagsNotification = @"HPNoteManagerDidUpdateTagsNotification";

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
        [self updateTagsOfNote:object];
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
    note.managed = YES;
    note.order = [self nextOrderInTag:nil];
    for (NSString *tag in note.tags)
    {
        NSInteger order = [self nextOrderInTag:tag];
        [note setOrder:order inTag:tag];
    }
    [_notes addObject:note];
    [note addObserver:self forKeyPath:NSStringFromSelector(@selector(text)) options:NSKeyValueObservingOptionNew context:HPNoteManagerContext];
    [self addTagsOfNote:note];
}

- (NSInteger)nextOrderInTag:(NSString*)tag;
{
    __block NSInteger maxOrder = 0;
    NSArray *notes = tag ? [self notesWithTag:tag] : _notes;
    [notes enumerateObjectsUsingBlock:^(HPNote *note, NSUInteger idx, BOOL *stop)
    {
        if (note.order > maxOrder)
        {
            maxOrder = note.order;
        }
    }];
    return maxOrder + 1;
}

- (NSArray*)notesWithTag:(NSString*)tag
{
    NSSet *set = [_tags objectForKey:tag];
    if (!set)
    {
        return [NSArray array];
    }
    else
    {
        return [set allObjects];
    }
}

- (void)removeNote:(HPNote*)note
{
    note.managed = NO;
    [_notes removeObject:note];
    [note removeObserver:self forKeyPath:NSStringFromSelector(@selector(text))];
    [self removeTagsOfNote:note];
}

- (NSArray*)tags
{
    return [_tags allKeys];
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
            return [HPNoteManager sortedNotes:notes selector:@selector(views) ascending:NO];
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
        HPNote *note = [HPNote noteWithText:text];
        [self addNote:note];
    }
}

- (void)addTagsOfNote:(HPNote*)note
{
    BOOL updated = NO;
    for (NSString *tag in note.tags)
    {
        updated |= [self addNote:note forTag:tag];
    }
    if (updated)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:HPNoteManagerDidUpdateTagsNotification object:self];
    }
}

- (BOOL)addNote:(HPNote*)note forTag:(NSString*)tag
{
    BOOL updated = NO;
    NSMutableSet *notes = [_tags objectForKey:tag];
    if (!notes)
    {
        notes = [NSMutableSet set];
        [_tags setObject:notes forKey:tag];
        updated = YES;
    };
    [notes addObject:note];
    return updated;
}

- (void)removeTagsOfNote:(HPNote*)note
{
    BOOL updated = NO;
    for (NSString *tag in note.tags)
    {
        updated |= [self removeNote:note forTag:tag];
    }
    if (updated)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:HPNoteManagerDidUpdateTagsNotification object:self];
    }
}

- (BOOL)removeNote:(HPNote*)note forTag:(NSString*)tag
{
    BOOL updated = NO;
    NSMutableSet *notes = [_tags objectForKey:tag];
    if (notes)
    {
        [notes removeObject:note];
        if (notes.count == 0)
        {
            [_tags removeObjectForKey:tag];
            updated = YES;
        }
    }
    return YES;
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

- (void)updateTagsOfNote:(HPNote*)note
{
    BOOL updated = NO;
    for (NSString *tag in note.removedTags)
    {
        updated |= [self removeNote:note forTag:tag];
    }
    for (NSString *tag in note.addedTags)
    {
        updated |= [self addNote:note forTag:tag];
    }
    if (updated)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:HPNoteManagerDidUpdateTagsNotification object:self];
    }
}

@end
