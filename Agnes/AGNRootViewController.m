//
//  AGNRootViewController.m
//  Agnes
//
//  Created by Hermés Piqué on 08/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNRootViewController.h"
#import "AGNPreferencesManager.h"
#import "AGNNoteListViewController.h"
#import "AGNNoteViewController.h"
#import "AGNRootPadViewController.h"
#import "AGNRootPhoneViewController.h"
#import "HPIndexViewController.h"
#import "HPNoteNavigationController.h"
#import "HPAgnesNavigationController.h"
#import "HPNoteListDetailTransitionAnimator.h"
#import "HPTagManager.h"
#import "HPIndexItem.h"
#import "HPModelManager.h"
#import "HPTracker.h"
#import <iRate/iRate.h>

@implementation AGNRootViewController {
    BOOL _prompForRating;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPModelManagerWillReplaceModelNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor whiteColor];
    
    HPIndexItem *indexItem = [self lastIndexItem] ? : [HPIndexItem inboxIndexItem];
    _listViewController = [[AGNNoteListViewController alloc] initWithIndexItem:indexItem];
    _listViewController.delegate = self;
    _listNavigationController = [[HPNoteNavigationController alloc] initWithRootViewController:_listViewController];
    _listNavigationController.delegate = self;
    
    _indexViewController = [HPIndexViewController new];
    [_indexViewController selectIndexItem:indexItem];
    _indexNavigationController = [[HPAgnesNavigationController alloc] initWithRootViewController:_indexViewController];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willReplaceModelNotification:) name:HPModelManagerWillReplaceModelNotification object:nil];
}

#pragma mark UIResponder

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (NSUndoManager*)undoManager
{
    return [HPNoteManager sharedManager].context.undoManager;
}

#pragma mark Public

- (void)setListIndexItem:(HPIndexItem*)indexItem animated:(BOOL)animated
{
    [[HPTracker defaultTracker] trackScreenWithName:indexItem.listScreenName];
    [[HPTagManager sharedManager] viewTag:indexItem.tag];
    _listViewController.indexItem = indexItem;
    if (_listNavigationController.topViewController != _listViewController)
    {
        [_listNavigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)showBlankNote
{
    _listViewController.indexItem = [HPIndexItem inboxIndexItem];
    [_listViewController showBlankNoteAnimated:NO];
}

- (void)viewDidLoadAddChildViewController:(UIViewController *)childController
{
    [self addChildViewController:childController];
    [self.view addSubview:childController.view];
    [childController didMoveToParentViewController:self];
}

- (void)willReplaceModel
{
    if (self.listNavigationController.topViewController != self.listViewController)
    {
        [self.listNavigationController popToRootViewControllerAnimated:YES];
    }
}

+ (instancetype)rootViewController
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? [AGNRootPhoneViewController new] : [AGNRootPadViewController new];
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

#pragma mark Private

- (HPIndexItem*)lastIndexItem
{
    NSString *lastViewedTagName = [AGNPreferencesManager sharedManager].lastViewedTagName;
    if (!lastViewedTagName) return nil;
    
    HPTag *lastViewedTag = [[HPTagManager sharedManager] tagForName:lastViewedTagName];
    if (!lastViewedTag) return nil;
    
    HPIndexItem *indexItem = [HPIndexItem indexItemWithTag:lastViewedTag];
    return indexItem.noteCount > 0 ? indexItem : nil;
}

#pragma mark Notifications

- (void)willReplaceModelNotification:(NSNotification*)notification
{
    [self willReplaceModel];
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
