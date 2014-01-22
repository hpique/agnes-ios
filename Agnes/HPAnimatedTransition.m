//
//  HPAnimatedTransition.m
//  Agnes
//
//  Created by Hermes on 22/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAnimatedTransition.h"
#import "HPNoteListViewController.h"
#import "HPNoteViewController.h"
#import "HPNoteTableViewCell.h"

@implementation HPAnimatedTransition

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    id fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    id toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if ([fromViewController isKindOfClass:[HPNoteListViewController class]] && [toViewController isKindOfClass:[HPNoteViewController class]])
    {
        [self animateTransition:transitionContext fromList:fromViewController toDetail:toViewController];
    } else if ([fromViewController isKindOfClass:[HPNoteViewController class]] && [toViewController isKindOfClass:[HPNoteListViewController class]])
    {
        [self animateTransition:transitionContext fromDetail:fromViewController toList:toViewController];
    }
}


- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext fromList:(HPNoteListViewController*)fromViewController toDetail:(HPNoteViewController*)toViewController
{
    [transitionContext.containerView addSubview:toViewController.view];
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    
    UITableView *tableView = fromViewController.tableView;
    NSIndexPath *selectedIndexPath = [tableView indexPathForSelectedRow];
    CGRect startRect = [tableView rectForRowAtIndexPath:selectedIndexPath];
    startRect = [transitionContext.containerView convertRect:startRect fromView:tableView];
    
    HPNoteTableViewCell *cell = (HPNoteTableViewCell*)[tableView cellForRowAtIndexPath:selectedIndexPath];
    UIView *cellReplacement = [[UIView alloc] initWithFrame:startRect];
    cellReplacement.backgroundColor = [UIColor whiteColor];
    [transitionContext.containerView addSubview:cellReplacement];

    UIView *toViewPlaceholder = [self coverView:toViewController.view withColor:[UIColor whiteColor] inContext:transitionContext];
    [transitionContext.containerView bringSubviewToFront:toViewController.view];
    [transitionContext.containerView bringSubviewToFront:fromViewController.view];
    
    UIView *cellPlaceholder = [self coverView:cell withColor:[UIColor whiteColor] inContext:transitionContext];
    UIView *titleLabelPlaceholder = [self fakeView:cell.titleLabel inContext:transitionContext];
    UIView *bodyLabelPlaceholder = [self fakeView:cell.bodyLabel inContext:transitionContext];
    
    UITextView *noteTextView = toViewController.noteTextView;
    toViewController.view.alpha = 0;
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration / 2 animations:^{
        CGPoint titleOrigin = [self originForLabel:cell.titleLabel inTextView:noteTextView context:transitionContext];
        CGPoint bodyOrigin = [self originForLabel:cell.bodyLabel inTextView:noteTextView context:transitionContext];
        titleLabelPlaceholder.frame = CGRectMake(titleOrigin.x, titleOrigin.y, titleLabelPlaceholder.frame.size.width, titleLabelPlaceholder.frame.size.height);
        bodyLabelPlaceholder.frame = CGRectMake(bodyOrigin.x, bodyOrigin.y, bodyLabelPlaceholder.frame.size.width, bodyLabelPlaceholder.frame.size.height);
        
        fromViewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [cellPlaceholder removeFromSuperview];
        [UIView animateWithDuration:duration / 2 animations:^{
            titleLabelPlaceholder.alpha = 0;
            bodyLabelPlaceholder.alpha = 0;
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [cellPlaceholder removeFromSuperview];
            [toViewPlaceholder removeFromSuperview];
            [titleLabelPlaceholder removeFromSuperview];
            [bodyLabelPlaceholder removeFromSuperview];
            [transitionContext completeTransition:YES];
        }];
    }];
}

- (CGPoint)originForLabel:(UILabel*)label inTextView:(UITextView*)textView context:(id <UIViewControllerContextTransitioning>)context
{
    NSLayoutManager *layoutManager = textView.layoutManager;
    NSRange charRange = [textView.text rangeOfString:label.text];
    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:charRange actualCharacterRange:nil];
    CGRect rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textView.textContainer];
    rect = CGRectOffset(rect, textView.textContainerInset.left, textView.textContainerInset.top);
    rect = [context.containerView convertRect:rect fromView:textView];
    return rect.origin;
}


- (UIView*)coverView:(UIView*)view withColor:(UIColor*)color inContext:(id <UIViewControllerContextTransitioning>)context
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, 0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CGContextFillRect(ctx, view.bounds);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];

    UIView *containerView = context.containerView;
    CGRect frame = [containerView convertRect:view.frame fromView:view.superview];
    imageView.frame = frame;
    [containerView addSubview:imageView];
    return imageView;
}

- (UIImage*)imageFromView:(UIView *)view
{
    CGSize imageSize = [view bounds].size;
    UIGraphicsBeginImageContextWithOptions(imageSize, view.opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [view.layer.presentationLayer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIView*)fakeView:(UIView*)view inContext:(id <UIViewControllerContextTransitioning>)context
{
    UIImage *image = [self imageFromView:view];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
    UIView *containerView = context.containerView;
    CGRect frame = [containerView convertRect:view.frame fromView:view.superview];
    imageView.frame = frame;
    [containerView addSubview:imageView];
    return imageView;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext fromDetail:(HPNoteViewController*)fromViewController toList:(HPNoteListViewController*)toViewController
{
    toViewController.view.alpha = 1;
    [transitionContext.containerView addSubview:toViewController.view];
    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        fromViewController.view.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
    } completion:^(BOOL finished) {
        [transitionContext completeTransition:YES];
    }];
}

@end



