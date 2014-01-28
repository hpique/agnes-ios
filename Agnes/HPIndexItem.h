//
//  HPIndexItem.h
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPTag.h"

@interface HPIndexItem : NSObject

@property (nonatomic, strong) NSArray *allowedSortModes;
@property (nonatomic, readonly) BOOL disableAdd;
@property (nonatomic, readonly) BOOL disableRemove;
@property (nonatomic, readonly) NSString* emptySubtitle;
@property (nonatomic, readonly) UIFont* emptySubtitleFont;
@property (nonatomic, readonly) NSString* emptyTitle;
@property (nonatomic, readonly) UIFont* emptyTitleFont;
@property (nonatomic, readonly) NSString *exportPrefix;
@property (nonatomic, readonly) UIImage *icon;
@property (nonatomic, readonly) NSString *indexTitle;
@property (nonatomic, readonly) NSArray *notes;
@property (nonatomic, assign) HPTagSortMode sortMode;
@property (nonatomic, readonly) HPTag *tag;
@property (nonatomic, copy) NSString *title;


+ (HPIndexItem*)inboxIndexItem;

+ (HPIndexItem*)archiveIndexItem;

+ (HPIndexItem*)indexItemWithTag:(NSString*)tagName;

+ (HPIndexItem*)systemIndexItem;

- (NSArray*)notes:(BOOL)archived;

@end