//
//  HPNoteNavigationController.m
//  Agnes
//
//  Created by Hermes on 26/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteNavigationController.h"
#import "HPNoteViewController.h"
#import "HPNoteListViewController.h"
#import "HPNote.h"

@interface HPNoteNavigationController ()

@end

@implementation HPNoteNavigationController

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    UIViewController *topViewContoller = self.topViewController;
    if ([topViewContoller isKindOfClass:[HPNoteListViewController class]])
    {
        HPNoteListViewController *listViewController = (HPNoteListViewController*)topViewContoller;
        listViewController.willTransitionToNote = YES;
    }
    [super pushViewController:viewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *topViewContoller = self.topViewController;
    if ([topViewContoller isKindOfClass:[HPNoteViewController class]])
    {
        HPNoteViewController *noteViewController = (HPNoteViewController*)topViewContoller;
        [noteViewController saveNote:NO /* animated */];
        noteViewController.willTransitionToList = YES;
    }
    return [super popViewControllerAnimated:animated];
}

@end
