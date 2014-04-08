//
//  AGNRootPhoneViewController.m
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNRootPhoneViewController.h"
#import <MMDrawerController/MMDrawerController.h>

@implementation AGNRootPhoneViewController {
    MMDrawerController *_drawerController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _drawerController = [[MMDrawerController alloc] initWithCenterViewController:self.listNavigationController leftDrawerViewController:self.indexNavigationController];
    _drawerController.closeDrawerGestureModeMask = MMOpenDrawerGestureModeAll;
    _drawerController.openDrawerGestureModeMask = MMOpenDrawerGestureModePanningNavigationBar | MMOpenDrawerGestureModeBezelPanningCenterView;
    
    [self viewDidLoadAddChildViewController:_drawerController];
}

#pragma mark AGNRootViewController

- (void)setListIndexItem:(HPIndexItem*)indexItem animated:(BOOL)animated
{
    [super setListIndexItem:indexItem animated:animated];
    [self closeDrawerAnimated:animated];
}

- (void)showBlankNote
{
    [super showBlankNote];
    [self closeDrawerAnimated:YES];
}

- (void)willReplaceModel
{
    [super willReplaceModel];
    [self closeDrawerAnimated:YES];
}

#pragma mark Private

- (void)closeDrawerAnimated:(BOOL)animated
{
    if (_drawerController.openSide != MMDrawerSideNone)
    {
        [_drawerController closeDrawerAnimated:animated completion:nil];
    }
}

@end
