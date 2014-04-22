//
//  AGNRootViewController.h
//  Agnes
//
//  Created by Hermés Piqué on 08/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AGNNoteListViewController.h"
@class HPIndexViewController;

@interface AGNRootViewController : UIViewController<UINavigationControllerDelegate, AGNNoteListViewControllerDelegate>

@property (nonatomic, readonly) HPIndexViewController *indexViewController;

@property (nonatomic, readonly) UINavigationController *indexNavigationController;

@property (nonatomic, readonly) AGNNoteListViewController *listViewController;

@property (nonatomic, readonly) UINavigationController *listNavigationController;

- (void)setListIndexItem:(HPIndexItem*)indexItem animated:(BOOL)animated;

- (void)showBlankNote;

- (void)willReplaceModel;

- (void)viewDidLoadAddChildViewController:(UIViewController *)childController;

+ (instancetype)rootViewController;

@end

@interface UIViewController(AGNRootViewController)

@property(nonatomic, strong, readonly) AGNRootViewController* agn_rootViewController;

@end
