//
//  HPNoteListViewController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HPIndexItem;
@class HPNote;

@interface HPNoteListViewController : UIViewController

@property (nonatomic, strong) HPIndexItem *indexItem;
@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic, assign) BOOL willTransitionToNote;

+ (UINavigationController*)controllerWithIndexItem:(HPIndexItem*)indexItem;

@property (nonatomic, readonly) NSIndexPath *indexPathOfSelectedNote;

- (BOOL)selectNote:(HPNote*)note;

@end
