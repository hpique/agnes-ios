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

@interface HPIndexItemInbox : HPIndexItem
@end

@interface HPIndexItemTag : HPIndexItem
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
}

@synthesize emptySubtitle = _emptySubtitle;
@synthesize emptyTitle = _emptyTitle;
@synthesize emptySubtitleFont = _emptySubtitleFont;
@synthesize emptyTitleFont = _emptyTitleFont;
@synthesize tag = _tag;

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
    HPIndexItemTag *item = [[HPIndexItemTag alloc] init];
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

- (NSString*)exportPrefix
{
    return self.title;
}

- (UIImage*)icon
{
    NSArray *notes = [self notes:NO /* archived */];
    UIImage *image = nil;
    if (notes.count > 0)
    {
        NSString *fullImageName = [NSString stringWithFormat:@"%@-full", _imageName];
        image = [UIImage imageNamed:fullImageName];
    }
    if (!image)
    {
        image = [UIImage imageNamed:_imageName];
    }
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    return image;
}

- (NSString*)indexTitle
{
    return self.title;
}

- (NSArray*)notes
{
    return [self notes:NO /* archived */];
}

- (NSArray*)notes:(BOOL)archived
{
    return @[];
}

- (void)setSortMode:(HPTagSortMode)sortMode
{
    [[HPPreferencesManager sharedManager] setSortMode:sortMode forListTitle:self.title];
}

- (HPTagSortMode)sortMode
{
    return [[HPPreferencesManager sharedManager] sortModeForListTitle:self.title default:self.defaultSortMode];
}

@end

@implementation HPIndexItemInbox

- (NSArray*)notes:(BOOL)archived
{
    NSArray *notes = [HPNoteManager sharedManager].objects;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %d", NSStringFromSelector(@selector(cd_archived)), archived];
    return [notes filteredArrayUsingPredicate:predicate];
}

@end

@implementation HPIndexItemArchive

- (NSArray*)notes
{
    return [self notes:YES /* archived */];
}

- (NSArray*)notes:(BOOL)archived
{
    NSArray *notes = [HPNoteManager sharedManager].objects;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == YES", NSStringFromSelector(@selector(cd_archived))];
    return [notes filteredArrayUsingPredicate:predicate];
}

@end

@implementation HPIndexItemTag

- (NSArray*)notes:(BOOL)archived
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %d", NSStringFromSelector(@selector(cd_archived)), archived];
    NSSet *notes = [self.tag.cd_notes filteredSetUsingPredicate:predicate];
    return [notes allObjects];
}

- (NSString*)indexTitle
{
    return [self.tag.name stringByReplacingOccurrencesOfString:@"#" withString:@""];
}

- (NSString*)exportPrefix
{
    return self.indexTitle;
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

@end

@implementation HPIndexItemSystem

- (NSArray*)notes:(BOOL)archived
{
    return [HPNoteManager sharedManager].systemNotes;
}

@end
