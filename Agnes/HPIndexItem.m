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

@interface HPIndexItemTag : HPIndexItem

@end

@interface HPIndexItemSystem : HPIndexItem

@end

@interface HPIndexItemPredicate : HPIndexItem

@property (nonatomic, strong) NSPredicate *predicate;

+ (HPIndexItemPredicate*)indexItemWithTitle:(NSString*)title predictate:(NSPredicate *)predicate;

@end

@implementation HPIndexItem {
    BOOL _disableAdd;
    BOOL _disableRemove;
}

+ (HPIndexItem*)inboxIndexItem
{
    static HPIndexItem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == NO", NSStringFromSelector(@selector(cd_archived))];
        instance = [HPIndexItemPredicate indexItemWithTitle:NSLocalizedString(@"Inbox", @"") predictate:predicate];
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
        NSString *archivedName = NSStringFromSelector(@selector(cd_archived));
        NSPredicate *archivePredicate = [NSPredicate predicateWithFormat:@"%K == YES", archivedName];
        instance = [HPIndexItemPredicate indexItemWithTitle:NSLocalizedString(@"Archive", @"") predictate:archivePredicate];
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

@end

@implementation HPIndexItemTag

- (NSArray*)notes
{
    HPTag *tag = [[HPTagManager sharedManager] tagWithName:self.tag];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == NO", NSStringFromSelector(@selector(cd_archived))];
    NSSet *notes = [tag.notes filteredSetUsingPredicate:predicate];
    return [notes allObjects];
}

- (NSString*)tag
{
    return self.title;
}

@end

@implementation HPIndexItemPredicate

+ (HPIndexItemPredicate*)indexItemWithTitle:(NSString*)title predictate:(NSPredicate *)predicate
{
    HPIndexItemPredicate *item = [[HPIndexItemPredicate alloc] init];
    item.title = title;
    item.predicate = predicate;
    return item;
}

- (NSArray*)notes
{
    NSArray *notes = [HPNoteManager sharedManager].objects;
    return [notes filteredArrayUsingPredicate:self.predicate];
}

@end

@implementation HPIndexItemSystem

- (NSArray*)notes
{
    return [HPNoteManager sharedManager].systemNotes;
}

@end
