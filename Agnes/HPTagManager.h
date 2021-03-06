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

- (HPTag*)tagForName:(NSString*)name;

- (HPTag*)tagWithName:(NSString*)name;

@end

@interface HPTagManager (Actions)

- (void)archiveNote:(HPNote*)note;

- (void)reorderTags:(NSArray*)tags exchangeObjectAtIndex:(NSUInteger)fromIndex withObjectAtIndex:(NSUInteger)toIndex;

- (void)removeDuplicates;

- (void)unarchiveNote:(HPNote*)note;

- (void)viewTag:(HPTag*)tag;

@end
