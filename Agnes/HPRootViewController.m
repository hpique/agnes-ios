//
//  HPRootViewController.m
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPRootViewController.h"
#import "HPNoteManager.h"
#import "HPNoteListDetailTransitionAnimator.h"
#import <CoreData/CoreData.h>

@implementation HPRootViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.closeDrawerGestureModeMask = MMCloseDrawerGestureModeAll;
    self.openDrawerGestureModeMask = MMOpenDrawerGestureModePanningNavigationBar | MMOpenDrawerGestureModePanningCenterView;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (NSUndoManager*)undoManager
{
    return [HPNoteManager sharedManager].context.undoManager;
}

#pragma mark - UINavigationControllerDelegate

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    if ([HPNoteListDetailTransitionAnimator canTransitionFromViewController:fromVC toViewController:toVC])
    {
        HPNoteListDetailTransitionAnimator *animator = [[HPNoteListDetailTransitionAnimator alloc] init];
        return animator;
    }
    return nil;
}

@end

@implementation UIViewController(HPRootViewController)

-(HPRootViewController*)hp_rootViewController
{
    UIViewController *parentViewController = self.parentViewController;
    while (parentViewController != nil)
    {
        if ([parentViewController isKindOfClass:[HPRootViewController class]])
        {
            return (HPRootViewController *)parentViewController;
        }
        parentViewController = parentViewController.parentViewController;
    }
    return nil;
}

@end

