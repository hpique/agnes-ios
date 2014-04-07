//
//  HPAgnesViewController.m
//  Agnes
//
//  Created by Hermes on 04/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAgnesViewController.h"
#import "AGNPreferencesManager.h"

@interface HPAgnesViewController ()

@end

@implementation HPAgnesViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // TODO: Use view controller based status bar appearance. First fix bug in MMDrawerController that causes the left view controller to glitch on appearence.
    AGNPreferencesManager *preferences = [AGNPreferencesManager sharedManager];
    const BOOL statusBarHidden = preferences.statusBarHidden;
    UIApplication *app = [UIApplication sharedApplication];
    if (app.statusBarHidden != statusBarHidden)
    {
        const UIStatusBarAnimation animation = animated ? UIStatusBarAnimationSlide : UIStatusBarAnimationNone;
        [app setStatusBarHidden:statusBarHidden withAnimation:animation];
    }
    
    const UIStatusBarStyle statusBarStyle = preferences.statusBarStyle;
    if (app.statusBarStyle != statusBarStyle)
    {
        [app setStatusBarStyle:statusBarStyle animated:animated];
    }
}

@end
