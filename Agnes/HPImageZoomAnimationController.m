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

@implementation HPImageZoomAnimationController {
    UIImageView *_imageView;
    UIImage *_image;
}

- (id)initWithImageView:(UIImageView *)imageView
{
    NSAssert(imageView.contentMode == UIViewContentModeScaleAspectFill, @"Image view must have a UIViewContentModeScaleAspectFill contentMode");
    if (self = [super init])
    {
        _imageView = imageView;
    }
    return self;
}

- (id)initWithImage:(UIImage *)image
{
    if (self = [super init])
    {
        _image = image;
    }
    return self;
}

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *viewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    return viewController.isBeingPresented ? 0.5 : 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *viewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if (viewController.isBeingPresented)
    {
        [self animateZoomInTransition:transitionContext];
    }
    else
    {
        [self animateZoomOutTransition:transitionContext];
    }
}

- (void)animateZoomInTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Get the view controllers participating in the transition
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    HPImageViewController *toViewController = (HPImageViewController *)[transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    NSAssert([toViewController isKindOfClass:HPImageViewController.class], @"Destination view controller must be a HPImageViewController");
    
    UIView *containerView = transitionContext.containerView;
    
    // Create a temporary view for the zoom in transition and set the initial frame based
    // on the reference image view
    UIImageView *transitionView = [[UIImageView alloc] initWithImage:self.referenceImage];
    transitionView.contentMode = UIViewContentModeScaleAspectFill;
    transitionView.clipsToBounds = YES;
    
    const CGRect referenceRect = [self referenceRectInContext:transitionContext];
    transitionView.frame = [containerView convertRect:referenceRect fromView:fromViewController.view];
    
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
    [containerView addSubview:toViewController.view];
    [containerView sendSubviewToBack:toViewController.view];
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    toViewController.view.alpha = 0;
    [toViewController.view layoutIfNeeded];
    
    // Compute the initial frame for the temporary view based on the image view
    // of the TGRImageViewController
    CGRect transitionViewInitialFrame = [fromViewController.imageView.image hp_aspectFitRectForSize:fromViewController.imageView.bounds.size];
    transitionViewInitialFrame = [transitionContext.containerView convertRect:transitionViewInitialFrame
                                                                     fromView:fromViewController.imageView];
    
    const CGRect referenceRect = [self referenceRectInContext:transitionContext];
    CGRect transitionViewFinalFrame = [transitionContext.containerView convertRect:referenceRect fromView:toViewController.view];
    
    UIView *coverView;
    if (self.coverColor)
    {
        coverView = [[UIView alloc] initWithFrame:referenceRect];
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

#pragma mark Private

- (UIImage*)referenceImage
{
    return _image ? : _imageView.image;
}

- (CGRect)referenceRectInContext:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *fromView = fromViewController.view;
    CGRect imageRect;
    if ([self.delegate respondsToSelector:@selector(imageZoomTransition:rectInView:)])
    {
        imageRect = [self.delegate imageZoomTransition:self rectInView:fromView];
    }
    else
    {
        imageRect = [fromView convertRect:_imageView.bounds fromView:_imageView];
    }
    return imageRect;
}

@end
