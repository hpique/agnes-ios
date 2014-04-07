//
//  AGNRootViewController.m
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNRootViewController.h"
#import "HPNoteManager.h"
#import "HPNoteListDetailTransitionAnimator.h"
#import "AGNNoteListViewController.h"
#import "HPPreferencesManager.h"
#import "HPIndexViewController.h"
#import "AGNNoteViewController.h"
#import "HPIndexItem.h"
#import "HPTracker.h"
#import "HPTagManager.h"
#import "HPModelManager.h"
#import <iRate/iRate.h>
#import <CoreData/CoreData.h>

@interface AGNRootViewController()<AGNNoteListViewControllerDelegate>

@end

@implementation AGNRootViewController {
    AGNNoteListViewController *_listViewController;
    HPIndexViewController *_indexViewController;
    BOOL _prompForRating;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPModelManagerWillReplaceModelNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.closeDrawerGestureModeMask = MMOpenDrawerGestureModeAll;
    self.openDrawerGestureModeMask = MMOpenDrawerGestureModePanningNavigationBar | MMOpenDrawerGestureModeBezelPanningCenterView;
    self.view.backgroundColor = [UIColor whiteColor];
    
    HPIndexItem *indexItem = [self lastIndexItem] ? : [HPIndexItem inboxIndexItem];
    _listViewController = [[AGNNoteListViewController alloc] initWithIndexItem:indexItem];
    _listViewController.delegate = self;
    HPNoteNavigationController *centerController = [[HPNoteNavigationController alloc] initWithRootViewController:_listViewController];
    centerController.delegate = self;
    
    _indexViewController = [HPIndexViewController new];
    [_indexViewController selectIndexItem:indexItem];
    HPAgnesNavigationController *leftController = [[HPAgnesNavigationController alloc] initWithRootViewController:_indexViewController];
    self.centerViewController = centerController;
    self.leftDrawerViewController = leftController;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willReplaceModelNotification:) name:HPModelManagerWillReplaceModelNotification object:nil];
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (NSUndoManager*)undoManager
{
    return [HPNoteManager sharedManager].context.undoManager;
}

#pragma mark Public

- (HPIndexItem*)indexItem
{
    return _listViewController.indexItem;
}

- (void)setListIndexItem:(HPIndexItem*)indexItem animated:(BOOL)animated
{
    [[HPTracker defaultTracker] trackScreenWithName:indexItem.listScreenName];
    [[HPTagManager sharedManager] viewTag:indexItem.tag];
    _listViewController.indexItem = indexItem;
    if (self.openSide != MMDrawerSideNone)
    {
        [self closeDrawerAnimated:animated completion:nil];
    }
    UINavigationController *navigationController = (UINavigationController*)self.centerViewController;
    if (navigationController.topViewController != _listViewController)
    {
        [navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)showBlankNote
{
    _listViewController.indexItem = [HPIndexItem inboxIndexItem];
    [_listViewController showBlankNoteAnimated:NO];
    if (self.openSide != MMDrawerSideNone)
    {
        [self closeDrawerAnimated:YES completion:nil];
    }
}

#pragma mark Private

- (HPIndexItem*)lastIndexItem
{
    NSString *lastViewedTagName = [HPPreferencesManager sharedManager].lastViewedTagName;
    if (!lastViewedTagName) return nil;
    
    HPTag *lastViewedTag = [[HPTagManager sharedManager] tagForName:lastViewedTagName];
    if (!lastViewedTag) return nil;
    
    HPIndexItem *indexItem = [HPIndexItem indexItemWithTag:lastViewedTag];
    return indexItem.noteCount > 0 ? indexItem : nil;
}

#pragma mark UINavigationControllerDelegate

- (id <UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                   animationControllerForOperation:(UINavigationControllerOperation)operation
                                                fromViewController:(UIViewController *)fromVC
                                                  toViewController:(UIViewController *)toVC
{
    _prompForRating = [fromVC isKindOfClass:[AGNNoteViewController class]] && [toVC isKindOfClass:[AGNNoteListViewController class]]  && [iRate sharedInstance].shouldPromptForRating;
    
    if ([HPNoteListDetailTransitionAnimator canTransitionFromViewController:fromVC toViewController:toVC])
    {
        HPNoteListDetailTransitionAnimator *animator = [[HPNoteListDetailTransitionAnimator alloc] init];
        return animator;
    }
    return nil;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (_prompForRating)
    {
        [[iRate sharedInstance] promptForRating];
        _prompForRating = NO;
    }
}

#pragma mark AGNNoteListViewControllerDelegate

- (void)noteListViewController:(AGNNoteListViewController*)viewController didChangeIndexItem:(HPIndexItem*)indexItem
{
    [_indexViewController selectIndexItem:indexItem];
}

#pragma mark Notifications

- (void)willReplaceModelNotification:(NSNotification*)notification
{
    if (self.openSide != MMDrawerSideNone)
    {
        [self closeDrawerAnimated:YES completion:nil];
    }
    UINavigationController *navigationController = (UINavigationController*)self.centerViewController;
    if (navigationController.topViewController != _listViewController)
    {
        [navigationController popToRootViewControllerAnimated:YES];
    }
}

@end

@implementation UIViewController(AGNRootViewController)

-(AGNRootViewController*)agn_rootViewController
{
    UIViewController *parentViewController = self.parentViewController;
    while (parentViewController != nil)
    {
        if ([parentViewController isKindOfClass:[AGNRootViewController class]])
        {
            return (AGNRootViewController *)parentViewController;
        }
        parentViewController = parentViewController.parentViewController;
    }
    return nil;
}

@end

