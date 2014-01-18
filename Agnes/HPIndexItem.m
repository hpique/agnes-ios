//
//  HPIndexItem.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPIndexItem.h"
#import "HPNote.h"

@implementation HPIndexItem

+ (HPIndexItem*)indexItemWithTitle:(NSString*)title predictate:(NSPredicate *)predicate
{
    HPIndexItem *item = [[HPIndexItem alloc] init];
    item.title = title;
    item.predicate = predicate;
    return item;
}

+ (HPIndexItem*)allNotesIndexItem
{
    static HPIndexItem *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.%@ == NO", NSStringFromSelector(@selector(archived))];
        instance = [HPIndexItem indexItemWithTitle:NSLocalizedString(@"All Notes", @"") predictate:predicate];
    });
    return instance;
}

@end
