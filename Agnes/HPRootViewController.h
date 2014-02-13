//
//  HPRootViewController.h
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "MMDrawerController.h"
@class HPIndexItem;

@interface HPRootViewController : MMDrawerController<UINavigationControllerDelegate>

- (void)setListIndexItem:(HPIndexItem*)indexItem animated:(BOOL)animated;

- (void)showBlankNote;

@end

@interface UIViewController(HPRootViewController)

@property(nonatomic, strong, readonly) HPRootViewController* hp_rootViewController;

@end
