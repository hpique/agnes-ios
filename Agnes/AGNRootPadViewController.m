//
//  AGNRootPadViewController.m
//  Agnes
//
//  Created by Hermés Piqué on 08/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNRootPadViewController.h"
#import "HPIndexItem.h"
#import "HPIndexViewController.h"
#import "UIImage+hp_utils.h"
#import <Lyt/Lyt.h>
#import <iOS7Colors/UIColor+iOS7Colors.h>

static CGFloat const AGNIndexWidth = 280;

@implementation AGNRootPadViewController {
    NSLayoutConstraint *_indexLeftConstraint;
    NSLayoutConstraint *_listLeftConstraint;
    UIButton *_toggleIndexButton;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor iOS7lightGrayColor];
    
    [self viewDidLoadAddChildViewController:self.indexNavigationController];
    [self viewDidLoadAddChildViewController:self.listNavigationController];
    
    {
        UIView *controllerView = self.indexNavigationController.view;
        controllerView.translatesAutoresizingMaskIntoConstraints = NO;
        [controllerView lyt_setWidth:AGNIndexWidth];
        [controllerView lyt_alignTopToParent];
        _indexLeftConstraint = [controllerView lyt_alignLeftToParent];
        [controllerView lyt_alignBottomToParent];
    }
    
    {
        UIView *controllerView = self.listNavigationController.view;
        controllerView.translatesAutoresizingMaskIntoConstraints = NO;
        [controllerView lyt_alignTopToParent];
        _listLeftConstraint = [controllerView lyt_placeRightOfView:self.indexNavigationController.view margin:1];
        [controllerView lyt_alignRightToParent];
        [controllerView lyt_alignBottomToParent];
    }
    
    {
        UIImage *hashtagImage = [[UIImage imageNamed:@"icon-hashtag"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _toggleIndexButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _toggleIndexButton.tintColor = [UIColor whiteColor];
        [_toggleIndexButton setBackgroundImage:hashtagImage forState:UIControlStateNormal];
        _toggleIndexButton.frame = CGRectMake(20, 28, hashtagImage.size.width, hashtagImage.size.height);
        [_toggleIndexButton addTarget:self action:@selector(toggleIndexButtonAction:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:_toggleIndexButton];
        [self.view bringSubviewToFront:self.indexNavigationController.view];
    }
    {
        UIImage *image = [UIImage imageNamed:@"icon-left"];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(toggleIndexBarButtonAction:)];
        self.indexViewController.navigationItem.leftBarButtonItem = barButton;
    }
    
    [self setListBackIndicatorImageForFullscreen:NO];
}

#pragma mark Actions

- (void)toggleIndexBarButtonAction:(UIBarButtonItem*)barButtonItem
{
    [self toggleIndex];
}

- (void)toggleIndexButtonAction:(UIButton*)button
{
    [self toggleIndex];
}

#pragma mark UINavigationController

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([self.superclass instancesRespondToSelector:@selector(navigationController:willShowViewController:animated:)])
    {
        [super navigationController:navigationController willShowViewController:viewController animated:animated];
    }
    if ([viewController isKindOfClass:AGNNoteListViewController.class])
    {
        _toggleIndexButton.hidden = NO;
    }
    else
    {
        _toggleIndexButton.hidden = YES;
    }
}


#pragma mark Toggling the index

- (void)toggleIndex
{
    const BOOL hide = _indexLeftConstraint.constant == 0;
    if (hide)
    {
        [self.indexNavigationController viewWillDisappear:YES];
    }
    else
    {
        [self.indexNavigationController viewWillAppear:YES];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [self setListBackIndicatorImageForFullscreen:hide];
        _indexLeftConstraint.constant = hide ? - AGNIndexWidth : 0;
        _listLeftConstraint.constant = hide ? 0 : 1;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (hide)
        {
            [self.indexNavigationController viewDidDisappear:YES];
        }
        else
        {
            [self.indexNavigationController viewDidAppear:YES];
        }
    }];
}

#pragma mark Appearence

- (void)setListBackIndicatorImageForFullscreen:(BOOL)fullscreen
{
    UINavigationBar *listNavigationBar = self.listNavigationController.navigationBar;
    // The image must have a size for the animation to look right
    UIImage *backIndicatorImage = fullscreen ? nil : [UIImage hp_imageWithColor:[UIColor clearColor] size:CGSizeMake(10, 22)];
    listNavigationBar.backIndicatorImage = backIndicatorImage;
    listNavigationBar.backIndicatorTransitionMaskImage = backIndicatorImage;
    
}

@end
