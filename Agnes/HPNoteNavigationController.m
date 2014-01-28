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
    [self setTransitioningInViewController:self.topViewController];
    [self setTransitioningInViewController:viewController];
    [super pushViewController:viewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    UIViewController *topViewContoller = self.topViewController;
    [self setTransitioningInViewController:topViewContoller];
    const NSInteger count = self.viewControllers.count;
    if (count > 1)
    {
        UIViewController *backViewController = self.viewControllers[count - 2];
        [self setTransitioningInViewController:backViewController];
    }
    if ([topViewContoller isKindOfClass:[HPNoteViewController class]])
    {
        HPNoteViewController *noteViewController = (HPNoteViewController*)topViewContoller;
        [noteViewController saveNote:NO /* animated */];
    }
    return [super popViewControllerAnimated:animated];
}

#pragma mark - Private

- (void)setTransitioningInViewController:(UIViewController*)viewController
{
    if ([viewController conformsToProtocol:@protocol(HPNoteTransitionViewController)])
    {
        id<HPNoteTransitionViewController> transitioningViewController = (id<HPNoteTransitionViewController>)viewController;
        transitioningViewController.transitioning = YES;
    }
}

@end
