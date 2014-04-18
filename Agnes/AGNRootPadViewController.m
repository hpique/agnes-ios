//
//  AGNRootPadViewController.m
//  Agnes
//
//  Created by Hermés Piqué on 08/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNRootPadViewController.h"
#import "HPAgnesUIMetrics.h"
#import "HPIndexItem.h"
#import "HPIndexViewController.h"
#import "UIImage+hp_utils.h"
#import <Lyt/Lyt.h>
#import <iOS7Colors/UIColor+iOS7Colors.h>

static CGFloat AGNIndexHiddenMargin;
static CGFloat const AGNIndexShownMargin = 0;

@implementation AGNRootPadViewController {
    NSLayoutConstraint *_indexLeftConstraint;
    UIButton *_toggleIndexButton;
    CGRect _startingPanRect;
    
    BOOL _indexHidden;
    BOOL _indexAnimating;
    CGFloat _indexLeftConstraintPanBeganValue;
}

+ (void)initialize
{
    AGNIndexHiddenMargin = - AGNIndexWidthPad - 1;
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
        [controllerView lyt_setWidth:AGNIndexWidthPad];
        [controllerView lyt_alignTopToParent];
        _indexLeftConstraint = [controllerView lyt_alignLeftToParent];
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
    
    UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
    panGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:panGestureRecognizer];
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

- (void)panGestureRecognized:(UIPanGestureRecognizer*)panGestureRecognizer
{
    switch (panGestureRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            _indexLeftConstraintPanBeganValue = _indexLeftConstraint.constant;
            break;
        case UIGestureRecognizerStateChanged:
        {
            const CGPoint translatedPoint = [panGestureRecognizer translationInView:self.view];
            CGFloat margin = _indexLeftConstraintPanBeganValue + translatedPoint.x;
            margin = MAX(AGNIndexHiddenMargin, MIN(margin, AGNIndexShownMargin));
            _indexLeftConstraint.constant = margin;
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            const CGPoint translatedPoint = [panGestureRecognizer translationInView:self.view];
            CGFloat margin = _indexLeftConstraintPanBeganValue + translatedPoint.x;
            const CGFloat deltaHidden = fabs(margin - AGNIndexHiddenMargin);
            const CGFloat deltaShown = fabs(AGNIndexShownMargin - margin);
            const BOOL hidden = deltaHidden < deltaShown;
            const CGPoint velocity = [panGestureRecognizer velocityInView:self.view];
            [self setIndexHidden:hidden velocity:velocity.x];
            break;
        }
        default:
            break;
    }
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
    [self setIndexHidden:!_indexHidden velocity:0];
}

- (void)setIndexHidden:(BOOL)hidden velocity:(CGFloat)velocity
{
    if (hidden != _indexHidden)
    {
        if (hidden)
        {
            [self.indexNavigationController viewWillDisappear:YES];
        }
        else
        {
            [self.indexNavigationController viewWillAppear:YES];
        }
    }
    
    _indexAnimating = YES;


    const CGFloat nextMargin = hidden ? AGNIndexHiddenMargin : AGNIndexShownMargin;
    const CGFloat delta = fabs(_indexLeftConstraint.constant - nextMargin);
    static CGFloat const MaximumDuration = 0.3;
    const NSTimeInterval duration = velocity == 0 ? MaximumDuration : MIN(delta / fabs(velocity), MaximumDuration);
    
    [UIView animateWithDuration:duration delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0 // Surprisingly, this works better than with fabs(velocity)
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
        [self setListBackIndicatorImageForFullscreen:hidden];
        _indexLeftConstraint.constant = nextMargin;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        _indexAnimating = NO;
        if (hidden != _indexHidden)
        {
            _indexHidden = hidden;
            if (hidden)
            {
                [self.indexNavigationController viewDidDisappear:YES];
            }
            else
            {
                [self.indexNavigationController viewDidAppear:YES];
            }
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

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return !_indexAnimating;
}

@end
