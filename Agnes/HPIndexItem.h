//
//  HPIndexItem.h
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPNoteManager.h"

@interface HPIndexItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, readonly) NSString *indexTitle;
@property (nonatomic, readonly) NSString *tag;
@property (nonatomic, readonly) NSArray *notes;
@property (nonatomic, readonly) BOOL disableAdd;
@property (nonatomic, readonly) BOOL disableRemove;
@property (nonatomic, assign) HPNoteDisplayCriteria defaultDisplayCriteria;
@property (nonatomic, readonly) UIImage *icon;
@property (nonatomic, strong) NSArray *allowedDisplayCriteria;
@property (nonatomic, readonly) NSString *exportPrefix;

+ (HPIndexItem*)inboxIndexItem;

+ (HPIndexItem*)archiveIndexItem;

+ (HPIndexItem*)indexItemWithTag:(NSString*)tag;

+ (HPIndexItem*)systemIndexItem;

@end