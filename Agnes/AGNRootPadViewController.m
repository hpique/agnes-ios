//
//  AGNRootPadViewController.m
//  Agnes
//
//  Created by Hermés Piqué on 08/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNRootPadViewController.h"
#import "HPIndexItem.h"
#import <Lyt/Lyt.h>

@implementation AGNRootPadViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self viewDidLoadAddChildViewController:self.indexNavigationController];
    [self viewDidLoadAddChildViewController:self.listNavigationController];
    
    {
        UIView *controllerView = self.indexNavigationController.view;
        controllerView.translatesAutoresizingMaskIntoConstraints = NO;
        [controllerView lyt_setWidth:240];
        [controllerView lyt_alignTopToParent];
        [controllerView lyt_alignLeftToParent];
        [controllerView lyt_alignBottomToParent];
    }
    
    {
        UIView *controllerView = self.listNavigationController.view;
        controllerView.translatesAutoresizingMaskIntoConstraints = NO;
        [controllerView lyt_alignTopToParent];
        [controllerView lyt_placeRightOfView:self.indexNavigationController.view margin:1];
        [controllerView lyt_alignRightToParent];
        [controllerView lyt_alignBottomToParent];
    }
}

@end
