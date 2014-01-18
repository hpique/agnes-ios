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

@interface HPIndexItemPredicate()

+ (HPIndexItemPredicate*)indexItemWithTitle:(NSString*)title predictate:(NSPredicate *)predicate;

@end

@implementation HPIndexItem {
    BOOL _protectedList;
}

+ (HPIndexItem*)inboxIndexItem
{
    static HPIndexItem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.%@ == NO", NSStringFromSelector(@selector(archived))];
        instance = [HPIndexItemPredicate indexItemWithTitle:NSLocalizedString(@"Inbox", @"") predictate:predicate];
    });
    return instance;
}

+ (HPIndexItem*)archiveIndexItem
{
    static HPIndexItem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *archivedName = NSStringFromSelector(@selector(archived));
        NSPredicate *archivePredicate = [NSPredicate predicateWithFormat:@"SELF.%@ == YES", archivedName];
        instance = [HPIndexItemPredicate indexItemWithTitle:NSLocalizedString(@"Archive", @"") predictate:archivePredicate];
        instance->_protectedList = YES;
    });
    return instance;
}

+ (HPIndexItem*)indexItemWithTag:(NSString*)tag
{
    HPIndexItemTag *item = [[HPIndexItemTag alloc] init];
    item.title = tag;
    return item;
}

- (BOOL)protectedList
{
    return _protectedList;
}

@end

@implementation HPIndexItemTag

- (NSArray*)notes
{
    return [[HPNoteManager sharedManager] notesWithTag:self.title];
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
    NSArray *notes = [HPNoteManager sharedManager].notes;
    return [notes filteredArrayUsingPredicate:self.predicate];
}

@end
