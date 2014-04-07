//
//  AGNRootViewController.h
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "MMDrawerController.h"
@class HPIndexItem;

@interface AGNRootViewController : MMDrawerController<UINavigationControllerDelegate>

- (void)setListIndexItem:(HPIndexItem*)indexItem animated:(BOOL)animated;

- (void)showBlankNote;

@end

@interface UIViewController(AGNRootViewController)

@property(nonatomic, strong, readonly) AGNRootViewController* agn_rootViewController;

@end
