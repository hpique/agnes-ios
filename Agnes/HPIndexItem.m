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
#import "HPtag.h"
#import "HPFontManager.h"

@interface HPIndexItemInbox : HPIndexItem
@end

@interface HPIndexItemTag : HPIndexItem
@end

@interface HPIndexItemArchive : HPIndexItem
@end

@interface HPIndexItemSystem : HPIndexItem
@end

@interface HPIndexItem ()

@property (nonatomic, copy) NSString* emptyTitle;
@property (nonatomic, copy) NSString* emptySubtitle;
@property (nonatomic, strong) UIFont* emptyTitleFont;
@property (nonatomic, strong) UIFont* emptySubtitleFont;
@property (nonatomic, copy) NSString *imageName;

@end


@implementation HPIndexItem {
    BOOL _disableAdd;
    BOOL _disableRemove;
    NSString *_imageName;
    NSString *_emptySubtitle;
    NSString *_emptyTitle;
    UIFont *_emptyTitleFont;
    UIFont *_emptySubtitleFont;
}

@synthesize emptySubtitle = _emptySubtitle;
@synthesize emptyTitle = _emptyTitle;
@synthesize emptySubtitleFont = _emptySubtitleFont;
@synthesize emptyTitleFont = _emptyTitleFont;

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
        instance.defaultDisplayCriteria = HPNoteDisplayCriteriaOrder;
        instance.allowedDisplayCriteria = @[@(HPNoteDisplayCriteriaOrder), @(HPNoteDisplayCriteriaModifiedAt), @(HPNoteDisplayCriteriaAlphabetical), @(HPNoteDisplayCriteriaViews)];
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
        instance.defaultDisplayCriteria = HPNoteDisplayCriteriaModifiedAt;
        instance.allowedDisplayCriteria = @[@(HPNoteDisplayCriteriaModifiedAt), @(HPNoteDisplayCriteriaAlphabetical), @(HPNoteDisplayCriteriaViews)];
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
        instance.defaultDisplayCriteria = HPNoteDisplayCriteriaViews;
        instance.allowedDisplayCriteria = @[@(HPNoteDisplayCriteriaAlphabetical), @(HPNoteDisplayCriteriaViews)];
        instance->_disableAdd = YES;
        instance->_disableRemove = YES;
    });
    return instance;
}

+ (HPIndexItem*)indexItemWithTag:(NSString*)tag
{
    HPIndexItemTag *item = [[HPIndexItemTag alloc] init];
    item.title = tag;
    item.imageName = @"icon-hashtag";
    item.emptyTitle = NSLocalizedString(@"No notes", @"");
    item.emptySubtitle = NSLocalizedString(@"Empty tags will disappear from the index", @"");
    item.defaultDisplayCriteria = HPNoteDisplayCriteriaOrder;
    item.allowedDisplayCriteria = @[@(HPNoteDisplayCriteriaOrder), @(HPNoteDisplayCriteriaModifiedAt), @(HPNoteDisplayCriteriaAlphabetical), @(HPNoteDisplayCriteriaViews)];
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
    HPTag *tag = [[HPTagManager sharedManager] tagWithName:self.tag];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %d", NSStringFromSelector(@selector(cd_archived)), archived];
    NSSet *notes = [tag.cd_notes filteredSetUsingPredicate:predicate];
    return [notes allObjects];
}

- (NSString*)indexTitle
{
    return [self.tag stringByReplacingOccurrencesOfString:@"#" withString:@""];
}

- (NSString*)tag
{
    return self.title;
}

- (NSString*)exportPrefix
{
    return [self.tag stringByReplacingOccurrencesOfString:@"#" withString:@""];
}

@end

@implementation HPIndexItemSystem

- (NSArray*)notes:(BOOL)archived
{
    return [HPNoteManager sharedManager].systemNotes;
}

@end
