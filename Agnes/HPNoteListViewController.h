//
//  HPNoteListViewController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
@class HPIndexItem;

@interface HPNoteListViewController : UIViewController

@property (nonatomic, strong) HPIndexItem *indexItem;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

+ (UIViewController*)controllerWithIndexItem:(HPIndexItem*)indexItem;

@end
