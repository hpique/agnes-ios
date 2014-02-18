//
//  HPNoteListViewController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPNoteNavigationController.h"
#import "HPAgnesViewController.h"
@class HPIndexItem;
@class HPNote;

@interface HPNoteListViewController : HPAgnesViewController<HPNoteTransitionViewController>

@property (nonatomic, strong) HPIndexItem *indexItem;
@property (nonatomic, readonly) UITableView *tableView;

@property (nonatomic, readonly) NSIndexPath *indexPathOfSelectedNote;

- (id)initWithIndexItem:(HPIndexItem*)indexItem;

- (BOOL)selectNote:(HPNote*)note;

- (void)showBlankNote;

@end
