//
//  HPImageZoomAnimationController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPImageZoomAnimationController.h"
#import "HPImageViewController.h"
#import "UIImage+hp_utils.h"

@interface HPImageZoomAnimationController()

@property (nonatomic, readonly) UIImage* referenceImage;
@property (nonatomic, readonly) CGRect referenceRect;
@property (nonatomic, readonly) UIView* referenceView;

@end

@implementation HPImageZoomAnimationController {
    UIImage *_referenceImage;
    CGRect _referenceRect;
    UIView *_referenceView;
}

@synthesize referenceImage = _referenceImage;
@synthesize referenceRect = _referenceRect;
@synthesize referenceView = _referenceView;

- (id)initWithReferenceImageView:(UIImageView *)referenceImageView {
    NSAssert(referenceImageView.contentMode == UIViewContentModeScaleAspectFill, @"*** referenceImageView must have a UIViewContentModeScaleAspectFill contentMode!");
    return [self initWithReferenceImage:referenceImageView.image
                                   view:referenceImageView
                                   rect:referenceImageView.bounds];
}

- (id)initWithReferenceImage:(UIImage*)image view:(UIView *)view rect:(CGRect)rect
{
    if (self = [super init]) {
        _referenceImage = image;
        _referenceView = view;
        _referenceRect = rect;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *viewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    return viewController.isBeingPresented ? 0.5 : 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *viewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if (viewController.isBeingPresented) {
        [self animateZoomInTransition:transitionContext];
    }
    else {
        [self animateZoomOutTransition:transitionContext];
    }
}

- (void)animateZoomInTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Get the view controllers participating in the transition
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HPImageViewController *toViewController = (HPImageViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    NSAssert([toViewController isKindOfClass:HPImageViewController.class], @"*** toViewController must be a TGRImageViewController!");
    
    UIView *containerView = transitionContext.containerView;
    
    // Create a temporary view for the zoom in transition and set the initial frame based
    // on the reference image view
    UIImageView *transitionView = [[UIImageView alloc] initWithImage:self.referenceImage];
    transitionView.contentMode = UIViewContentModeScaleAspectFill;
    transitionView.clipsToBounds = YES;
    transitionView.frame = [containerView convertRect:self.referenceRect fromView:self.referenceView];
    
    UIView *coverView;
    if (self.coverColor)
    {
        coverView = [[UIView alloc] initWithFrame:transitionView.frame];
        coverView.backgroundColor = self.coverColor;
        [containerView addSubview:coverView];
    }
    UIView *backgroundView = [[UIView alloc] initWithFrame:containerView.bounds];
    backgroundView.backgroundColor = [UIColor blackColor];
    backgroundView.alpha = 0;
    [containerView addSubview:backgroundView];
    
    [containerView addSubview:transitionView];
    
    // Compute the final frame for the temporary view
    CGRect finalFrame = [transitionContext finalFrameForViewController:toViewController];
    CGRect transitionViewFinalFrame = [self.referenceImage hp_aspectFitRectForSize:finalFrame.size];
    
    // Perform the transition using a spring motion effect
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:duration
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         backgroundView.alpha = 1;
                         transitionView.frame = transitionViewFinalFrame;
                     }
                     completion:^(BOOL finished) {
                         fromViewController.view.alpha = 1;
                         
                         [backgroundView removeFromSuperview];
                         [coverView removeFromSuperview];
                         [transitionView removeFromSuperview];
                         [transitionContext.containerView addSubview:toViewController.view];
                         
                         [transitionContext completeTransition:YES];
                     }];
}

- (void)animateZoomOutTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Get the view controllers participating in the transition
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    HPImageViewController *fromViewController = (HPImageViewController *)[transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    NSAssert([fromViewController isKindOfClass:HPImageViewController.class], @"*** fromViewController must be a TGRImageViewController!");
    
    UIView *containerView = transitionContext.containerView;
    
    // The toViewController view will fade in during the transition
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    toViewController.view.alpha = 0;
    [containerView addSubview:toViewController.view];
    [containerView sendSubviewToBack:toViewController.view];
    
    // Compute the initial frame for the temporary view based on the image view
    // of the TGRImageViewController
    CGRect transitionViewInitialFrame = [fromViewController.imageView.image hp_aspectFitRectForSize:fromViewController.imageView.bounds.size];
    transitionViewInitialFrame = [transitionContext.containerView convertRect:transitionViewInitialFrame
                                                                     fromView:fromViewController.imageView];
    
    // Compute the final frame for the temporary view based on the reference
    // image view
    CGRect transitionViewFinalFrame = [transitionContext.containerView convertRect:self.referenceRect
                                                                          fromView:self.referenceView];
    
    UIView *coverView;
    if (self.coverColor)
    {
        CGRect frame = [toViewController.view convertRect:_referenceRect fromView:_referenceView];
        coverView = [[UIView alloc] initWithFrame:frame];
        coverView.backgroundColor = self.coverColor;
        [toViewController.view addSubview:coverView];
    }
    
    // Create a temporary view for the zoom out transition based on the image
    // view controller contents
    UIImageView *transitionView = [[UIImageView alloc] initWithImage:fromViewController.imageView.image];
    transitionView.contentMode = UIViewContentModeScaleAspectFill;
    transitionView.clipsToBounds = YES;
    transitionView.frame = transitionViewInitialFrame;
    [containerView addSubview:transitionView];
    [fromViewController.view removeFromSuperview];
    
    // Perform the transition
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         toViewController.view.alpha = 1;
                         transitionView.frame = transitionViewFinalFrame;
                     } completion:^(BOOL finished) {
                         [coverView removeFromSuperview];
                         [transitionView removeFromSuperview];
                         [transitionContext completeTransition:YES];
                     }];
}


@end
