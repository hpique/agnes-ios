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
#import "HPNoteListViewController.h"
#import "HPIndexViewController.h"
#import "HPNoteViewController.h"
#import "HPIndexItem.h"
#import <CoreData/CoreData.h>

@interface HPRootViewController()

@end

@implementation HPRootViewController {
    HPNoteListViewController *_listViewController;
    HPIndexViewController *_indexViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.closeDrawerGestureModeMask = MMOpenDrawerGestureModeAll;
    self.openDrawerGestureModeMask = MMOpenDrawerGestureModePanningNavigationBar | MMOpenDrawerGestureModeBezelPanningCenterView;
    self.view.backgroundColor = [UIColor whiteColor];
    
    _listViewController = [[HPNoteListViewController alloc] init];
    _listViewController.indexItem = [HPIndexItem inboxIndexItem];
    HPNoteNavigationController *centerController = [[HPNoteNavigationController alloc] initWithRootViewController:_listViewController];
    centerController.delegate = self;
    _indexViewController = [[HPIndexViewController alloc] init];
    HPAgnesNavigationController *leftController = [[HPAgnesNavigationController alloc] initWithRootViewController:_indexViewController];
    self.centerViewController = centerController;
    self.leftDrawerViewController = leftController;
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (NSUndoManager*)undoManager
{
    return [HPNoteManager sharedManager].context.undoManager;
}

#pragma mark - Public

- (void)setListIndexItem:(HPIndexItem*)indexItem animated:(BOOL)animated
{
    _listViewController.indexItem = indexItem;
    if (self.openSide != MMDrawerSideNone)
    {
        [self closeDrawerAnimated:animated completion:nil];
    }
}

- (void)showBlankNote
{
    _listViewController.indexItem = [HPIndexItem inboxIndexItem];
    [_listViewController showBlankNote];
    if (self.openSide != MMDrawerSideNone)
    {
        [self closeDrawerAnimated:YES completion:nil];
    }
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

