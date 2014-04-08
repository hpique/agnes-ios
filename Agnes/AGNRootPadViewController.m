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
#import <iOS7Colors/UIColor+iOS7Colors.h>

static CGFloat const AGNIndexWidth = 240;

@implementation AGNRootPadViewController {
    NSLayoutConstraint *_indexLeftConstraint;
    NSLayoutConstraint *_listLeftConstraint;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor iOS7lightGrayColor];
    
    UIImage *hashtagImage = [UIImage imageNamed:@"icon-hashtag"];
    UIBarButtonItem *toggleIndexBarButtonItem = [[UIBarButtonItem alloc] initWithImage:hashtagImage style:UIBarButtonItemStylePlain target:self action:@selector(toggleIndexBarButtonAction:)];
    self.listViewController.navigationItem.leftBarButtonItem = toggleIndexBarButtonItem;
    
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
}

#pragma mark Actions

- (void)toggleIndexBarButtonAction:(UIBarButtonItem*)barButtonItem
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
    [self.indexNavigationController viewWillDisappear:YES];
    [UIView animateWithDuration:0.3 animations:^{
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

@end
