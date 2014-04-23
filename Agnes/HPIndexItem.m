//
//  HPIndexItem.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPIndexItem.h"
#import "HPNote.h"
#import "HPNoteManager.h"
#import "HPTagManager.h"
#import "AGNModelManager.h"
#import "HPFontManager.h"
#import "AGNPreferencesManager.h"

NSString* NSStringFromIndexSortMode(HPIndexSortMode sortMode)
{
    switch (sortMode)
    {
        case HPIndexSortModeOrder: return NSLocalizedString(@"manual order", @"");
        case HPIndexSortModeAlphabetical: return NSLocalizedString(@"a-z", @"");
        case HPIndexSortModeCount: return NSLocalizedString(@"by notes", @"");
    }
}

NSString* const HPIndexItemDidChangeNotification = @"HPIndexItemDidChangeNotification";

@interface HPIndexItemInbox : HPIndexItem
@end

@interface HPIndexItemArchive : HPIndexItem
@end

@interface HPIndexItemSystem : HPIndexItem
@end

@interface HPIndexItem ()

@property (nonatomic, assign) HPTagSortMode defaultSortMode;
@property (nonatomic, copy) NSString* emptyTitle;
@property (nonatomic, copy) NSString* emptySubtitle;
@property (nonatomic, strong) UIFont* emptyTitleFont;
@property (nonatomic, strong) UIFont* emptySubtitleFont;
@property (nonatomic, copy) NSString *imageName;
@property (nonatomic, strong) HPTag *tag;

@end

@implementation HPIndexItem {
    BOOL _disableAdd;
    BOOL _disableRemove;
    NSString *_imageName;
    NSString *_emptySubtitle;
    NSString *_emptyTitle;
    UIFont *_emptyTitleFont;
    UIFont *_emptySubtitleFont;
    HPTag *_tag;

    // Cache
    UIImage *_icon;
    NSUInteger _noteCount;
    NSArray *_notes;
}

@synthesize emptySubtitle = _emptySubtitle;
@synthesize emptyTitle = _emptyTitle;
@synthesize emptySubtitleFont = _emptySubtitleFont;
@synthesize emptyTitleFont = _emptyTitleFont;
@synthesize tag = _tag;

- (id)init
{
    self = [super init];
    if (self)
    {
        _noteCount = NSNotFound;
        [self startObserving];
    }
    return self;
}

- (void)dealloc
{
    [self stopObserving];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AGNModelManagerDidReplaceModelNotification object:nil];
}

+ (instancetype)inboxIndexItem
{
    static HPIndexItem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPIndexItemInbox alloc] init];
        instance.title = NSLocalizedString(@"Inbox", @"");
        instance.imageName = @"icon-inbox";
        instance.emptyTitle = NSLocalizedString(@"Empty Inbox", @"");
        instance.emptySubtitle = NSLocalizedString(@"Tap + to write a note", @"");
        instance.defaultSortMode = HPTagSortModeOrder;
        instance.allowedSortModes = @[@(HPTagSortModeOrder), @(HPTagSortModeModifiedAt), @(HPTagSortModeAlphabetical), @(HPTagSortModeViews), @(HPTagSortModeTag)];
    });
    return instance;
}

+ (instancetype)archiveIndexItem
{
    static HPIndexItem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPIndexItemArchive alloc] init];
        instance.title = NSLocalizedString(@"Archive", @"");
        instance.imageName = @"icon-archive";
        instance.emptyTitle = NSLocalizedString(@"Empty Archive", @"");
        instance.emptySubtitle = NSLocalizedString(@"Slide notes to the left to archive them", @"");
        instance.emptyTitleFont = [[HPFontManager sharedManager] fontForArchivedNoteTitle];
        instance.emptySubtitleFont = [[HPFontManager sharedManager] fontForArchivedNoteBody];
        instance.defaultSortMode = HPTagSortModeModifiedAt;
        instance.allowedSortModes = @[@(HPTagSortModeModifiedAt), @(HPTagSortModeAlphabetical), @(HPTagSortModeViews), @(HPTagSortModeTag)];
        instance->_disableAdd = YES;
    });
    return instance;
}

+ (instancetype)systemIndexItem
{
    static HPIndexItem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPIndexItemSystem alloc] init];
        instance.title = NSLocalizedString(@"Meta", @"");
        instance.imageName = @"icon-gear";
        instance.defaultSortMode = HPTagSortModeAlphabetical;
        instance.allowedSortModes = @[@(HPTagSortModeAlphabetical)];
        instance->_disableAdd = YES;
        instance->_disableRemove = YES;
    });
    return instance;
}

+ (instancetype)indexItemWithTag:(HPTag*)tag
{
    HPTagManager *tagManager = [HPTagManager sharedManager];
    if (tag == tagManager.inboxTag) return [HPIndexItem inboxIndexItem];
    if (tag == tagManager.archiveTag) return [HPIndexItem archiveIndexItem];
    
    HPIndexItem *item = [[HPIndexItem alloc] init];
    item.tag = tag;
    item.title = tag.name;
    item.imageName = @"icon-hashtag";
    item.emptyTitle = NSLocalizedString(@"No Notes", @"");
    item.emptySubtitle = NSLocalizedString(@"Empty tags will disappear from the Index", @"");
    item.defaultSortMode = HPTagSortModeOrder;
    item.allowedSortModes = @[@(HPTagSortModeOrder), @(HPTagSortModeModifiedAt), @(HPTagSortModeAlphabetical), @(HPTagSortModeViews)];
    return item;
}

- (BOOL)canExport
{
    return self.noteCount > 0;
}

- (BOOL)disableAdd
{
    return _disableAdd;
}

- (BOOL)disableRemove
{
    return _disableRemove;
}

- (UIFont*)emptyTitleFont
{
    if (_emptyTitleFont) return _emptyTitleFont;
    return [[HPFontManager sharedManager] fontForNoteTitle];
}

- (UIFont*)emptySubtitleFont
{
    if (_emptySubtitleFont) return _emptySubtitleFont;
    return [[HPFontManager sharedManager] fontForNoteBody];
}

- (BOOL)hideNoteCount
{
    return NO;
}

- (UIImage*)icon
{
    if (!_icon)
    {
        UIImage *image = [UIImage imageNamed:_imageName];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _icon = image;
    }
    return _icon;
}

- (NSString*)indexTitle
{
    return [self.tag.name stringByReplacingOccurrencesOfString:@"#" withString:@""];
}

- (NSString*)exportPrefix
{
    return self.indexTitle;
}

- (NSString*)listScreenName
{
    static NSString *const UserTagScreenName = @"Hashtag";
    NSString *screenName = self.tag.isSystem ? self.tag.name : UserTagScreenName;
    return screenName;
}

- (NSUInteger)noteCount
{
    if (_noteCount != NSNotFound) return _noteCount;
    if (_notes)
    {
        _noteCount = _notes.count;
    }
    else
    {
        _noteCount = self.notes.count;
    }
    return _noteCount;
}

- (NSArray*)notes
{
    if (!_notes)
    {
        _notes = [self notes:NO /* archived */];
    }
    return _notes;
}

- (NSArray*)notes:(BOOL)archived
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %d", NSStringFromSelector(@selector(cd_archived)), archived];
    NSSet *noteSet = [self.tag.cd_notes filteredSetUsingPredicate:predicate];
    NSArray *sortedNotes = [self sortedNotesFromSet:noteSet];
    return sortedNotes;
}

- (void)setSortMode:(HPTagSortMode)sortMode
{
    self.tag.sortMode = sortMode;
}

- (HPTagSortMode)sortMode
{
    NSNumber *value = self.tag.cd_sortMode;
    if (!value) return self.defaultSortMode;
    return [value integerValue];
}

#pragma mark Private

- (BOOL)hasChangedOrderForChangedAttributes:(NSDictionary*)attributes
{
    static NSString *modifiedAtName = nil;
    static NSString *tagOrderName = nil;
    static NSString *textName = nil;
    static NSString *viewsName = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tagOrderName = NSStringFromSelector(@selector(tagOrder));
        viewsName = NSStringFromSelector(@selector(cd_views));
        modifiedAtName = NSStringFromSelector(@selector(modifiedAt));
        textName = NSStringFromSelector(@selector(text));
    });
    NSString *attributeName = nil;
    const HPTagSortMode sortMode = self.tag.sortMode;
    switch (sortMode) {
        case HPTagSortModeAlphabetical:
            attributeName = textName;
            break;
        case HPTagSortModeOrder:
            attributeName = tagOrderName;
            break;
        case HPTagSortModeViews:
            attributeName = viewsName;
            break;
        case HPTagSortModeModifiedAt:
            attributeName = modifiedAtName;
            break;
        case HPTagSortModeTag:
            attributeName = textName;
            break;
    }
    id value = attributes[attributeName];
    return value != nil;
}

- (void)startObserving
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagsDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willReplaceModelNotification:) name:AGNModelManagerWillReplaceModelNotification object:nil];
}

- (void)stopObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AGNModelManagerWillReplaceModelNotification object:nil];
}

- (NSArray*)sortedNotesFromSet:(NSSet*)set
{
    NSArray *notes = set.allObjects;
    HPTag *tag = self.tag;
    switch (tag.sortMode)
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
            return [self sortedNotesFromArray:notes descriptor:sortDescriptor];
            break;
        }
        case HPTagSortModeModifiedAt:
        {
            static NSSortDescriptor *sortDescriptor = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(modifiedAt)) ascending:NO];
            });
            return [self sortedNotesFromArray:notes descriptor:sortDescriptor];
            break;
        }
        case HPTagSortModeViews:
        {
            static NSSortDescriptor *sortDescriptor = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(views)) ascending:NO];
            });
            return [self sortedNotesFromArray:notes descriptor:sortDescriptor];
            break;
        }
        case HPTagSortModeTag:
        {
            static NSSortDescriptor *sortDescriptor = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(firstTagName)) ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
            });
            return [self sortedNotesFromArray:notes descriptor:sortDescriptor];
            break;
        }
    }
    return notes;
}

- (NSArray*)sortedNotesFromArray:(NSArray*)notes descriptor:(NSSortDescriptor*)sortDescriptor
{
    static NSSortDescriptor *modifiedAtSortDescriptor = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        modifiedAtSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(modifiedAt)) ascending:NO];
    });
    return [notes sortedArrayUsingDescriptors:@[sortDescriptor, modifiedAtSortDescriptor]];
}

#pragma mark Notifications

- (void)notesDidChangeNotification:(NSNotification*)notification
{
    // TODO: When the user adds/removes a tag notes are invalidated twice: the tag change, and the text change.
    for (HPNote *note in notification.hp_changedObjects)
    {
        if ([note.cd_tags containsObject:self.tag])
        {
            NSDictionary *changedValues = note.changedValuesForCurrentEvent;
            const BOOL hasChangedOrder = [self hasChangedOrderForChangedAttributes:changedValues];
            if (hasChangedOrder)
            {
                [self invalidateNotesAndNotifyChange];
                return;
            }
        }
    }
}

- (void)tagsDidChangeNotification:(NSNotification*)notification
{
    HPTagManager *manager = [HPTagManager sharedManager];
    for (HPTag *tag in notification.hp_changedObjects)
    {
        if (self.tag == tag || tag == manager.archiveTag)
        {
            [self invalidateNotesAndNotifyChange];
            return;
        }
    }
}

- (void)didReplaceModelNotification:(NSNotification*)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AGNModelManagerDidReplaceModelNotification object:nil];
    [self startObserving];
}

- (void)willReplaceModelNotification:(NSNotification*)notification
{
    [self stopObserving];
    _noteCount = NSNotFound;
    _notes = nil;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReplaceModelNotification:) name:AGNModelManagerDidReplaceModelNotification object:nil];
}

- (void)invalidateNotesAndNotifyChange
{
    _noteCount = NSNotFound;
    _notes = nil;
    [[NSNotificationCenter defaultCenter] postNotificationName:HPIndexItemDidChangeNotification object:self];
}

@end

@implementation HPIndexItemInbox {
    UIImage *_iconFull;
}

- (HPTag*)tag
{
    return [HPTagManager sharedManager].inboxTag;
}

- (UIImage*)icon
{
    if (self.noteCount > 0)
    {
        if (!_iconFull)
        {
            NSString *fullImageName = [NSString stringWithFormat:@"%@-full", self.imageName];
            UIImage *image = [UIImage imageNamed:fullImageName];
            image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            _iconFull = image;
        }
        return _iconFull;
    }
    return [super icon];
}

- (NSArray*)notes:(BOOL)archived
{
    if (archived)
    {
        HPTag *archiveTag = [HPTagManager sharedManager].archiveTag;
        NSArray *sortedNotes = [self sortedNotesFromSet:archiveTag.cd_notes];
        return sortedNotes;
    }
    return [super notes:archived];
}

- (NSString*)indexTitle
{
    return self.title;
}

@end

@implementation HPIndexItemArchive

- (HPTag*)tag
{
    return [HPTagManager sharedManager].archiveTag;
}

- (NSArray*)notes
{
    return [self notes:YES /* archived */];
}

- (NSArray*)notes:(BOOL)archived
{
    NSArray *sortedNotes = [self sortedNotesFromSet:self.tag.cd_notes];
    return sortedNotes;
}

- (NSString*)indexTitle
{
    return self.title;
}

@end

@implementation HPIndexItemSystem

- (BOOL)canExport
{
    return NO;
}

- (HPTag*)tag
{ // For cell height calculations
    return [HPTagManager sharedManager].inboxTag;
}

- (NSArray*)notes:(BOOL)archived
{
    return [HPNoteManager sharedManager].systemNotes;
}

- (BOOL)hideNoteCount
{
    return YES;
}

- (NSString*)indexTitle
{
    return self.title;
}

- (NSString*)listScreenName
{
    return @"Meta";
}

- (HPTagSortMode)sortMode
{
    return self.defaultSortMode;
}

@end
