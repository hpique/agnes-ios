//
//  HPNoteListDetailTransitionAnimator.m
//  Agnes
//
//  Created by Hermes on 22/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteListDetailTransitionAnimator.h"
#import "HPNoteListViewController.h"
#import "AGNNoteViewController.h"
#import "HPNoteTableViewCell.h"
#import "HPNoteNavigationController.h"
#import "HPNote.h"
#import "HPNote+List.h"
#import "HPAttachment.h"
#import "UIImage+hp_utils.h"
#import "UITextView+hp_utils.h"
#import "PSPDFTextView.h"

@implementation HPNoteListDetailTransitionAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
    id fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    id toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    if ([fromViewController isKindOfClass:[HPNoteListViewController class]] && [toViewController isKindOfClass:[AGNNoteViewController class]])
    {
        [self animateTransition:transitionContext fromList:fromViewController toDetail:toViewController];
    } else if ([fromViewController isKindOfClass:[AGNNoteViewController class]] && [toViewController isKindOfClass:[HPNoteListViewController class]])
    {
        [self animateTransition:transitionContext fromDetail:fromViewController toList:toViewController];
    }
}

#pragma mark Public

+ (BOOL)canTransitionFromViewController:(UIViewController *)fromVC
                       toViewController:(UIViewController *)toVC
{
    if ([fromVC conformsToProtocol:@protocol(HPNoteTransitionViewController)])
    {
        id<HPNoteTransitionViewController> transitionViewController = (id<HPNoteTransitionViewController>)fromVC;
        if (transitionViewController.wantsDefaultTransition) return NO;
    }
    if ([toVC conformsToProtocol:@protocol(HPNoteTransitionViewController)])
    {
        id<HPNoteTransitionViewController> transitionViewController = (id<HPNoteTransitionViewController>)toVC;
        if (transitionViewController.wantsDefaultTransition) return NO;
    }
    if ([fromVC isKindOfClass:[HPNoteListViewController class]] && [toVC isKindOfClass:[AGNNoteViewController class]])
    {
        HPNoteListViewController *listViewController = (HPNoteListViewController*) fromVC;
        if (listViewController.indexPathOfSelectedNote)
        {
            return YES;
        }
    }
    if ([fromVC isKindOfClass:[AGNNoteViewController class]] && [toVC isKindOfClass:[HPNoteListViewController class]])
    {
        AGNNoteViewController *noteViewController = (AGNNoteViewController*) fromVC;
        HPNote *note = noteViewController.note;
        if (!note) return NO; // Note was trashed
        if ([note isNew]) return NO;
        
        HPNoteListViewController *listViewController = (HPNoteListViewController*) toVC;
        BOOL selected = [listViewController selectNote:note];
        if (selected)
        {
            return YES;
        }
    }
    return NO;
}

#pragma mark Private

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext fromList:(HPNoteListViewController*)fromViewController toDetail:(AGNNoteViewController*)toViewController
{
    UIView *containerView = transitionContext.containerView;
    [transitionContext.containerView addSubview:toViewController.view];
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    
    // HACK: We need to call this here to ensure that the text is properly positioned. Doing this in viewWillAppear: or viewWillLayoutSubviews conflicted with the animations.
    [toViewController.noteTextView scrollToVisibleCaretAnimated:NO];
    
    UITableView *tableView = fromViewController.tableView;
    NSIndexPath *selectedIndexPath = fromViewController.indexPathOfSelectedNote;
    CGRect startRect = [tableView rectForRowAtIndexPath:selectedIndexPath];
    startRect = [transitionContext.containerView convertRect:startRect fromView:tableView];
    
    HPNoteTableViewCell *cell = (HPNoteTableViewCell*)[tableView cellForRowAtIndexPath:selectedIndexPath];
    UIView *cellReplacement = [[UIView alloc] initWithFrame:startRect];
    cellReplacement.backgroundColor = [UIColor whiteColor];
    [transitionContext.containerView addSubview:cellReplacement];

    UIView *backgroundView = [self coverView:toViewController.view rect:toViewController.view.bounds color:[UIColor whiteColor] context:transitionContext];
    [transitionContext.containerView bringSubviewToFront:toViewController.view];
    [transitionContext.containerView bringSubviewToFront:fromViewController.view];
    
    UITextView *noteTextView = toViewController.noteTextView;
    UILabel *titleLabel = cell.titleLabel;
    UIView *titleLabelCover = nil;
    UIView *titleLabelPlaceholder = nil;
    NSString *title = cell.titleForTransition;
    CGRect titleRect;
    if (title)
    {
        titleRect = [self rectForText:title inTextView:noteTextView context:transitionContext];
        if (!CGRectIsNull(titleRect))
        {
            titleLabelCover = [self coverView:titleLabel rect:titleLabel.bounds color:[UIColor whiteColor] context:transitionContext];
            titleLabelPlaceholder = [self addSnapshotView:titleLabel rect:titleLabel.bounds context:transitionContext];
        }
    }
    
    UILabel *bodyLabel = cell.bodyLabel;
    UIView *bodyLabelCover = nil;
    UIView *bodyLabelPlaceholder = nil;
    NSString *body = cell.bodyForTransition;
    CGRect bodyRect;
    if (body)
    {
        bodyRect = [self rectForText:body inTextView:noteTextView context:transitionContext];
        if (!CGRectIsNull(bodyRect))
        {
            bodyLabelCover = [self coverView:bodyLabel rect:bodyLabel.bounds color:[UIColor whiteColor] context:transitionContext];
            bodyLabelPlaceholder = [self addSnapshotView:bodyLabel rect:bodyLabel.bounds context:transitionContext];
        }
    }
    
    UIView *thumbnailViewCover = nil;
    UIImageView *thumbnailViewPlaceholder = nil;
    UIImageView *thumbnailView = cell.thumbnailView;
    HPNote *note = cell.note;
    HPAttachment *thumbnailAttachment = note.thumbnailAttachment;
    NSInteger thumbnailCharacterIndex = NSNotFound;
    if (thumbnailAttachment)
    {
        thumbnailViewCover = [self coverView:thumbnailView rect:thumbnailView.bounds color:[UIColor whiteColor] context:transitionContext];
        thumbnailCharacterIndex = [self characterIndexForAttachment:thumbnailAttachment textView:noteTextView];
        if (thumbnailCharacterIndex != NSNotFound)
        {
            NSTextAttachment *attachment = [noteTextView.attributedText attribute:NSAttachmentAttributeName atIndex:thumbnailCharacterIndex effectiveRange:nil];
            thumbnailViewPlaceholder = [self addImageViewWithImage:attachment.image rect:thumbnailView.bounds fromView:thumbnailView context:transitionContext];
        }
    }
    
    if (titleLabelPlaceholder) [containerView bringSubviewToFront:titleLabelPlaceholder];
    if (bodyLabelPlaceholder) [containerView bringSubviewToFront:bodyLabelPlaceholder];
    if (thumbnailViewPlaceholder) [containerView bringSubviewToFront:thumbnailViewPlaceholder];
    noteTextView.alpha = 0;
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    NSTimeInterval firstDuration = duration * 2.0/3.0;
    NSTimeInterval secondDuration = duration - firstDuration;
    UIView *toolbar = toViewController.toolbar;
    toolbar.alpha = 0;
    [UIView animateWithDuration:firstDuration animations:^{
        if (titleLabelPlaceholder)
        {
            const CGPoint titleOrigin = titleRect.origin;
            titleLabelPlaceholder.frame = CGRectMake(titleOrigin.x, titleOrigin.y, titleLabelPlaceholder.frame.size.width, titleLabelPlaceholder.frame.size.height);
        }
        if (bodyLabelPlaceholder)
        {
            const CGPoint bodyOrigin = bodyRect.origin;
            bodyLabelPlaceholder.frame = CGRectMake(bodyOrigin.x, bodyOrigin.y, bodyLabelPlaceholder.frame.size.width, bodyLabelPlaceholder.frame.size.height);
        }
        if (thumbnailViewPlaceholder)
        {
            CGRect rect = [noteTextView hp_rectForCharacterRange:NSMakeRange(thumbnailCharacterIndex, 1)];
            rect = [transitionContext.containerView convertRect:rect fromView:noteTextView];
            thumbnailViewPlaceholder.frame = CGRectMake(rect.origin.x, rect.origin.y, thumbnailViewPlaceholder.image.size.width, thumbnailViewPlaceholder.image.size.height);
        }
        fromViewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [titleLabelCover removeFromSuperview];
        [bodyLabelCover removeFromSuperview];
        [thumbnailViewCover removeFromSuperview];
        toolbar.center = CGPointMake(toolbar.center.x, toolbar.center.y + toolbar.bounds.size.height);
        if (thumbnailViewPlaceholder)
        {
            CGRect frame = [toViewController.view convertRect:thumbnailViewPlaceholder.frame fromView:thumbnailViewPlaceholder.superview];
            [thumbnailViewPlaceholder removeFromSuperview];
            thumbnailViewPlaceholder.frame = frame;
            [toViewController.view addSubview:thumbnailViewPlaceholder];
            [toViewController.view bringSubviewToFront:toolbar];
        }
        [UIView animateWithDuration:secondDuration animations:^{
            titleLabelPlaceholder.alpha = 0;
            bodyLabelPlaceholder.alpha = 0;
            noteTextView.alpha = 1;
            toolbar.alpha = 1;
            toolbar.center = CGPointMake(toolbar.center.x, toolbar.center.y - toolbar.bounds.size.height);
        } completion:^(BOOL finished) {
            [backgroundView removeFromSuperview];
            [titleLabelPlaceholder removeFromSuperview];
            [bodyLabelPlaceholder removeFromSuperview];
            [thumbnailViewPlaceholder removeFromSuperview];
            [transitionContext completeTransition:YES];
            fromViewController.view.alpha = 1;
        }];
    }];
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext fromDetail:(AGNNoteViewController*)fromViewController toList:(HPNoteListViewController*)toViewController
{
    UIView *containerView = transitionContext.containerView;
    [containerView addSubview:toViewController.view];
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    
    UIView *backgroundView = [self coverView:toViewController.view rect:toViewController.view.bounds color:[UIColor whiteColor] context:transitionContext];
    [containerView bringSubviewToFront:toViewController.view];
    [containerView bringSubviewToFront:fromViewController.view];

    UITableView *tableView = toViewController.tableView;
    NSIndexPath *selectedIndexPath = toViewController.indexPathOfSelectedNote;
    if (!selectedIndexPath)
    {
        [toViewController selectNote:fromViewController.note];
        selectedIndexPath = [tableView indexPathForSelectedRow];
    }
    HPNoteTableViewCell *cell = (HPNoteTableViewCell*)[tableView cellForRowAtIndexPath:selectedIndexPath];
    
    UITextView *noteTextView = fromViewController.noteTextView;
    UILabel *titleLabel = cell.titleLabel;
    NSString *title = cell.titleForTransition;
    BOOL handleTitle = NO;
    UIView *titleCover = nil;
    CGRect titleRect;
    if (title)
    {
        titleRect = [noteTextView hp_rectForSubstring:title];
        if (!CGRectIsEmpty(titleRect))
        {
            handleTitle = YES;
            titleCover = [self coverView:noteTextView rect:titleRect color:[UIColor whiteColor] context:transitionContext];
        }
    }

    CGRect bodyRect;
    UIView *bodyCover;
    UILabel *bodyLabel = cell.bodyLabel;
    NSString *body = cell.bodyForTransition;
    const BOOL handleBody = bodyLabel.hidden == NO && body != nil;
    if (handleBody)
    {
        bodyRect = [noteTextView hp_rectForSubstring:body];
        bodyCover = [self coverView:noteTextView rect:bodyRect color:[UIColor whiteColor] context:transitionContext];
    }
    
    UIView *thumbnailCover, *thumbnailViewPlaceholder = nil;
    HPAttachment *thumbnailAttachment = cell.note.thumbnailAttachment;
    if (thumbnailAttachment)
    {
        NSInteger index = [self characterIndexForAttachment:thumbnailAttachment textView:noteTextView];
        CGRect thumbnailRect = [noteTextView hp_rectForCharacterRange:NSMakeRange(index, 1)];
        thumbnailCover = [self coverView:noteTextView rect:thumbnailRect color:[UIColor whiteColor] context:transitionContext];
        NSTextAttachment *textAttachment = [noteTextView.attributedText attribute:NSAttachmentAttributeName atIndex:index effectiveRange:nil];
        thumbnailViewPlaceholder = [self addImageViewWithImage:textAttachment.image rect:thumbnailRect fromView:noteTextView context:transitionContext];
    }
    
    UIView *titlePlaceholder = nil;
    if (handleTitle)
    {
        // TODO: Use titleLabel as if titleRect is not visible
        titlePlaceholder = [self addSnapshotView:noteTextView rect:titleRect context:transitionContext];
    }
    UIView *bodyPlaceholder;
    if (handleBody)
    {
        // TODO: Use bodyLabel if bodyRect is not visible
        bodyPlaceholder = [self addSnapshotView:noteTextView rect:bodyRect context:transitionContext];
    }
    
    toViewController.view.alpha = 0;
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    NSTimeInterval firstDuration = duration * 2.0/3.0;
    NSTimeInterval secondDuration = duration - firstDuration;
    
    [UIView animateWithDuration:firstDuration animations:^{
        if (handleTitle)
        {
            [self translateView:titlePlaceholder toView:titleLabel containerView:containerView];
        }
        if (handleBody)
        {
            [self translateView:bodyPlaceholder toView:bodyLabel containerView:containerView];
        }
        if (thumbnailViewPlaceholder)
        {
            UIImageView *thumbnailView = cell.thumbnailView;
            thumbnailViewPlaceholder.frame = [containerView convertRect:thumbnailView.bounds fromView:thumbnailView];
        }
        fromViewController.view.alpha = 0;
        UIView *toolbar = fromViewController.toolbar;
        toolbar.center = CGPointMake(toolbar.center.x, toolbar.center.y + toolbar.bounds.size.height);
    } completion:^(BOOL finished) {
        [titleCover removeFromSuperview];
        [bodyCover removeFromSuperview];
        [thumbnailCover removeFromSuperview];
        [UIView animateWithDuration:secondDuration animations:^{
            titlePlaceholder.alpha = 0;
            bodyPlaceholder.alpha = 0;
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [backgroundView removeFromSuperview];
            [titlePlaceholder removeFromSuperview];
            [bodyPlaceholder removeFromSuperview];
            [thumbnailViewPlaceholder removeFromSuperview];
            fromViewController.view.alpha = 1;
            [transitionContext completeTransition:YES];
        }];
    }];
}

- (NSInteger)characterIndexForAttachment:(HPAttachment*)attachment textView:(UITextView*)textView
{
    __block NSInteger characterIndex = NSNotFound;
    NSAttributedString *attributedText = textView.attributedText;
    [attributedText enumerateAttribute:HPNoteAttachmentAttributeName inRange:NSMakeRange(0, attributedText.length) options:kNilOptions usingBlock:^(HPAttachment *value, NSRange range, BOOL *stop) {
        if (!value) return;
        if (value != attachment) return;
        characterIndex = range.location;
    }];
    return characterIndex;
}

#pragma mark Utils

- (UIView*)coverView:(UIView*)view rect:(CGRect)rect color:(UIColor*)color context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIImage *image = [UIImage hp_imageWithColor:color size:rect.size];
    UIImageView *imageView = [self addImageViewWithImage:image rect:rect fromView:view context:transitionContext];
    return imageView;
}

- (UIView*)addSnapshotView:(UIView*)view rect:(CGRect)rect context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIView *snapshotView = [view resizableSnapshotViewFromRect:rect afterScreenUpdates:NO withCapInsets:UIEdgeInsetsZero];
    UIView *containerView = transitionContext.containerView;
    rect = [containerView convertRect:rect fromView:view];
    snapshotView.frame = rect;
    [containerView addSubview:snapshotView];
    return snapshotView;
}

- (UIImageView*)addImageViewWithImage:(UIImage*)image rect:(CGRect)rect fromView:(UIView*)view context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
    UIView *containerView = transitionContext.containerView;
    rect = [containerView convertRect:rect fromView:view];
    imageView.frame = rect;
    [containerView addSubview:imageView];
    return imageView;
}

- (CGRect)rectForText:(NSString*)text inTextView:(UITextView*)textView context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    CGRect rect = [textView hp_rectForSubstring:text];
    if (CGRectIsNull(rect)) return rect;
    rect = [transitionContext.containerView convertRect:rect fromView:textView];
    return rect;
}

- (void)translateView:(UIView*)fromView toView:(UIView*)toView containerView:(UIView*)containerView
{
    CGPoint toOrigin = [containerView convertRect:toView.frame fromView:toView.superview].origin;
    CGSize fromSize = fromView.frame.size;
    fromView.frame = CGRectMake(toOrigin.x, toOrigin.y, fromSize.width, fromSize.height);
}

@end
