//
//  HPTagManager.h
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPEntityManager.h"
@class HPTag;
@class HPNote;

@interface HPTagManager : HPEntityManager

+ (HPTagManager*)sharedManager;

#pragma mark System tags

- (HPTag*)archiveTag;

- (HPTag*)inboxTag;

#pragma mark Fetching objects

- (NSArray*)indexTags;

- (NSArray*)tagNamesWithPrefix:(NSString*)prefix;

- (HPTag*)tagWithName:(NSString*)name;

#pragma mark Operations

- (void)archiveNote:(HPNote*)note;

- (void)reorderTagsWithNames:(NSArray*)names;

- (void)removeDuplicates;

- (void)unarchiveNote:(HPNote*)note;

@end
