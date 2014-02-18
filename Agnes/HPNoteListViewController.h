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

@protocol HPNoteListViewControllerDelegate;

@interface HPNoteListViewController : HPAgnesViewController<HPNoteTransitionViewController>

@property (nonatomic, strong) HPIndexItem *indexItem;
@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, weak) id<HPNoteListViewControllerDelegate> delegate;

@property (nonatomic, readonly) NSIndexPath *indexPathOfSelectedNote;

- (id)initWithIndexItem:(HPIndexItem*)indexItem;

- (BOOL)selectNote:(HPNote*)note;

- (void)showBlankNote;

@end

@protocol HPNoteListViewControllerDelegate <NSObject>

- (void)noteListViewController:(HPNoteListViewController*)viewController didChangeIndexItem:(HPIndexItem*)indexItem;

@end