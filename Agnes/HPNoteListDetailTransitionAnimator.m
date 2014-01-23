//
//  HPNoteListDetailTransitionAnimator.m
//  Agnes
//
//  Created by Hermes on 22/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteListDetailTransitionAnimator.h"
#import "HPNoteListViewController.h"
#import "HPNoteViewController.h"
#import "HPNoteTableViewCell.h"

@interface UILabel(Utils)

- (NSRange)hp_visibleRange;

@end

@implementation HPNoteListDetailTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 1;
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

    UIView *backgroundView = [self coverView:toViewController.view color:[UIColor whiteColor] inContext:transitionContext];
    [transitionContext.containerView bringSubviewToFront:toViewController.view];
    [transitionContext.containerView bringSubviewToFront:fromViewController.view];
    
    UIView *cellCover = [self coverView:cell color:[UIColor whiteColor] inContext:transitionContext];
    UIView *titleLabelPlaceholder = [self fakeView:cell.titleLabel inContext:transitionContext];
    UIView *bodyLabelPlaceholder = [self fakeView:cell.bodyLabel inContext:transitionContext];
    
    UITextView *noteTextView = toViewController.noteTextView;
    toViewController.view.alpha = 0;
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    NSTimeInterval firstDuration = duration * 2.0/3.0;
    NSTimeInterval secondDuration = duration - firstDuration;
    [UIView animateWithDuration:firstDuration animations:^{
        CGPoint titleOrigin = [self originForLabel:cell.titleLabel inTextView:noteTextView context:transitionContext];
        CGPoint bodyOrigin = [self originForLabel:cell.bodyLabel inTextView:noteTextView context:transitionContext];
        titleLabelPlaceholder.frame = CGRectMake(titleOrigin.x, titleOrigin.y, titleLabelPlaceholder.frame.size.width, titleLabelPlaceholder.frame.size.height);
        bodyLabelPlaceholder.frame = CGRectMake(bodyOrigin.x, bodyOrigin.y, bodyLabelPlaceholder.frame.size.width, bodyLabelPlaceholder.frame.size.height);
        
        fromViewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [cellCover removeFromSuperview];
        [UIView animateWithDuration:secondDuration animations:^{
            titleLabelPlaceholder.alpha = 0;
            bodyLabelPlaceholder.alpha = 0;
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [backgroundView removeFromSuperview];
            [titleLabelPlaceholder removeFromSuperview];
            [bodyLabelPlaceholder removeFromSuperview];
            [transitionContext completeTransition:YES];
            fromViewController.view.alpha = 1;
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

- (UIView*)coverView:(UIView*)view color:(UIColor*)color inContext:(id <UIViewControllerContextTransitioning>)context
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
    CGSize imageSize = view.bounds.size;
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

- (UIView*)coverView:(UIView*)view rect:(CGRect)rect color:(UIColor*)color context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIGraphicsBeginImageContextWithOptions(rect.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, rect.size.width, rect.size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    
    UIView *containerView = transitionContext.containerView;
    CGRect frame = [containerView convertRect:rect fromView:view];
    imageView.frame = frame;
    [containerView addSubview:imageView];
    return imageView;
}

- (UIView*)fakeView:(UIView*)view rect:(CGRect)rect context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIGraphicsBeginImageContextWithOptions(rect.size, view.opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
    [view.layer.presentationLayer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    UIView *containerView = transitionContext.containerView;
    rect = [containerView convertRect:rect fromView:view];
    imageView.frame = rect;
    [containerView addSubview:imageView];
    return imageView;
}

- (CGRect)rectForLabel:(UILabel*)label inTextView:(UITextView*)textView
{
    NSRange visibleRange = [label hp_visibleRange];
    if (visibleRange.location == NSNotFound)
    {
        visibleRange = [textView.text lineRangeForRange:NSMakeRange(0, 0)];
    }
    NSString *substring = [label.text substringWithRange:visibleRange];
    NSLayoutManager *layoutManager = textView.layoutManager;
    NSRange charRange = [textView.text rangeOfString:substring];
    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:charRange actualCharacterRange:nil];
    CGRect rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textView.textContainer];
    rect = CGRectOffset(rect, textView.textContainerInset.left, textView.textContainerInset.top);
    return CGRectMake(rect.origin.x, rect.origin.y, ceil(rect.size.width), ceil(rect.size.height));
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext fromDetail:(HPNoteViewController*)fromViewController toList:(HPNoteListViewController*)toViewController
{
    UIView *containerView = transitionContext.containerView;
    [containerView addSubview:toViewController.view];
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    
    UIView *backgroundView = [self coverView:toViewController.view color:[UIColor whiteColor] inContext:transitionContext];
    [containerView bringSubviewToFront:toViewController.view];
    [containerView bringSubviewToFront:fromViewController.view];

    UITableView *tableView = toViewController.tableView;
    NSIndexPath *selectedIndexPath = [tableView indexPathForSelectedRow]; // The note must have been selected by the UINavigationControllerDelegate
    HPNoteTableViewCell *cell = (HPNoteTableViewCell*)[tableView cellForRowAtIndexPath:selectedIndexPath];
    
    UITextView *noteTextView = fromViewController.noteTextView;

    UILabel *titleLabel = cell.titleLabel;
    UILabel *bodyLabel = cell.bodyLabel;
    CGRect titleRect = [self rectForLabel:titleLabel inTextView:noteTextView];
    CGRect bodyRect = [self rectForLabel:bodyLabel inTextView:noteTextView];
    UIView *titleCover = [self coverView:noteTextView rect:titleRect color:[UIColor whiteColor] context:transitionContext];
    UIView *bodyCover = [self coverView:noteTextView rect:bodyRect color:[UIColor whiteColor] context:transitionContext];
    UIView *titlePlaceholder = [self fakeView:noteTextView rect:titleRect context:transitionContext];
    UIView *bodyPlaceholder = [self fakeView:noteTextView rect:bodyRect context:transitionContext];
    
    toViewController.view.alpha = 0;
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    NSTimeInterval firstDuration = duration * 2.0/3.0;
    NSTimeInterval secondDuration = duration - firstDuration;
    
    [UIView animateWithDuration:firstDuration animations:^{
        [self translateView:titlePlaceholder toView:titleLabel containerView:containerView];
        [self translateView:bodyPlaceholder toView:bodyLabel containerView:containerView];
        fromViewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [titleCover removeFromSuperview];
        [bodyCover removeFromSuperview];
        [UIView animateWithDuration:secondDuration animations:^{
            titlePlaceholder.alpha = 0;
            bodyPlaceholder.alpha = 0;
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [backgroundView removeFromSuperview];
            [titlePlaceholder removeFromSuperview];
            [bodyPlaceholder removeFromSuperview];
            [transitionContext completeTransition:YES];
            fromViewController.view.alpha = 1;
        }];
    }];
}

- (void)translateView:(UIView*)fromView toView:(UIView*)toView containerView:(UIView*)containerView
{
    CGPoint toOrigin = [containerView convertRect:toView.frame fromView:toView.superview].origin;
    CGSize fromSize = fromView.frame.size;
    fromView.frame = CGRectMake(toOrigin.x, toOrigin.y, fromSize.width, fromSize.height);
}

@end

@implementation UILabel(Utils)

- (NSRange)hp_visibleRange
{
    NSString *text = self.text;
    const NSInteger max = text.length - 1;
    NSInteger next = max;
    const CGSize labelSize = self.bounds.size;
    const CGSize maxSize = CGSizeMake(labelSize.width, CGFLOAT_MAX);
    NSRange visibleRange = NSMakeRange(NSNotFound, 0);
    NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    paragraphStyle.lineBreakMode = self.lineBreakMode;
    NSDictionary * attributes = @{NSFontAttributeName:self.font, NSParagraphStyleAttributeName:paragraphStyle};
    NSInteger right;
    NSInteger best = 0;
    do
    {
        right = next;
        NSRange range = NSMakeRange(0, right + 1);
        NSString *substring = [text substringWithRange:range];
        CGSize textSize = [substring boundingRectWithSize:maxSize
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:attributes
                                                  context:nil].size;
        if (textSize.width <= labelSize.width && textSize.height <= labelSize.height)
        {
            visibleRange = range;
            best = right;
            next = right + (max - right) / 2;
        } else if (right > 0)
        {
            next = right - (right - best) / 2;
        }
    } while (next != right);
    
    return visibleRange;
}

@end
