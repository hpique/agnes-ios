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
#import "HPFontManager.h"
#import "HPPreferencesManager.h"

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

@property (nonatomic, readonly) NSUInteger fasterNoteCount;

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagsDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
}

+ (HPIndexItem*)inboxIndexItem
{
    static HPIndexItem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPIndexItemInbox alloc] init];
        instance.title = NSLocalizedString(@"Inbox", @"");
        instance.imageName = @"icon-inbox";
        instance.emptyTitle = NSLocalizedString(@"No notes", @"");
        instance.emptySubtitle = NSLocalizedString(@"An empty inbox is a good inbox", @"");
        instance.defaultSortMode = HPTagSortModeOrder;
        instance.allowedSortModes = @[@(HPTagSortModeOrder), @(HPTagSortModeModifiedAt), @(HPTagSortModeAlphabetical), @(HPTagSortModeViews), @(HPTagSortModeTag)];
    });
    return instance;
}

+ (HPIndexItem*)archiveIndexItem
{
    static HPIndexItem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPIndexItemArchive alloc] init];
        instance.title = NSLocalizedString(@"Archive", @"");
        instance.imageName = @"icon-archive";
        instance.emptyTitle = NSLocalizedString(@"No notes", @"");
        instance.emptySubtitle = NSLocalizedString(@"Slide notes to the left to archive them", @"");
        instance.emptyTitleFont = [[HPFontManager sharedManager] fontForArchivedNoteTitle];
        instance.emptySubtitleFont = [[HPFontManager sharedManager] fontForArchivedNoteBody];
        instance.defaultSortMode = HPTagSortModeModifiedAt;
        instance.allowedSortModes = @[@(HPTagSortModeModifiedAt), @(HPTagSortModeAlphabetical), @(HPTagSortModeViews), @(HPTagSortModeTag)];
        instance->_disableAdd = YES;
    });
    return instance;
}

+ (HPIndexItem*)systemIndexItem
{
    static HPIndexItem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPIndexItemSystem alloc] init];
        instance.title = NSLocalizedString(@"Meta", @"");
        instance.imageName = @"icon-gear";
        instance.defaultSortMode = HPTagSortModeViews;
        instance.allowedSortModes = @[@(HPTagSortModeAlphabetical), @(HPTagSortModeViews)];
        instance->_disableAdd = YES;
        instance->_disableRemove = YES;
    });
    return instance;
}

+ (HPIndexItem*)indexItemWithTag:(HPTag*)tag
{
    HPIndexItem *item = [[HPIndexItem alloc] init];
    item.tag = tag;
    item.title = tag.name;
    item.imageName = @"icon-hashtag";
    item.emptyTitle = NSLocalizedString(@"No notes", @"");
    item.emptySubtitle = NSLocalizedString(@"Empty tags will disappear from the index", @"");
    item.defaultSortMode = HPTagSortModeOrder;
    item.allowedSortModes = @[@(HPTagSortModeOrder), @(HPTagSortModeModifiedAt), @(HPTagSortModeAlphabetical), @(HPTagSortModeViews)];
    return item;
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

- (NSUInteger)fasterNoteCount
{
    return self.tag.cd_notes.count;
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

- (NSUInteger)noteCount
{
    if (_noteCount != NSNotFound) return _noteCount;
    if (_notes)
    {
        _noteCount = _notes.count;
    }
    else
    {
        const NSUInteger fasterCount = self.fasterNoteCount;
        if (fasterCount != NSNotFound)
        {
            _noteCount = fasterCount;
        }
        else
        {
            _noteCount = self.notes.count;
        }
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
    NSSet *notes = [self.tag.cd_notes filteredSetUsingPredicate:predicate];
    return [notes allObjects];
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

#pragma mark Notifications

- (void)tagsDidChangeNotification:(NSNotification*)notification
{
    for (HPTag *tag in notification.hp_changedObjects)
    {
        if (self.tag == tag)
        {
            [self invalidateNotesAndNotifyChange];
            return;
        }
    }
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
        return archiveTag.cd_notes.allObjects;
    }
    return self.tag.cd_notes.allObjects;
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
    return self.tag.cd_notes.allObjects;
}

- (NSString*)indexTitle
{
    return self.title;
}

@end

@implementation HPIndexItemSystem

- (NSUInteger)fasterNoteCount
{
    return [HPNoteManager sharedManager].systemNotes.count;
}

- (HPTag*)tag
{ // For cell height calculations
    return [HPTagManager sharedManager].inboxTag;
}

- (NSArray*)notes:(BOOL)archived
{
    return [HPNoteManager sharedManager].systemNotes;
}

- (NSString*)indexTitle
{
    return self.title;
}

@end
