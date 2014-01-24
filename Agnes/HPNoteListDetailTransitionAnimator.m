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
#import "HPNote.h"

@interface UIView(Utils)

- (UIImage*)hp_imageFromRect:(CGRect)rect;

@end

@interface UILabel(Utils)

- (NSRange)hp_visibleRange;

@end

static UIImage* HPImageFromColor(UIColor *color, CGSize size)
{
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, size.width, size.height));
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@implementation HPNoteListDetailTransitionAnimator

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

#pragma mark - Public

+ (BOOL)canTransitionFromViewController:(UIViewController *)fromVC
                       toViewController:(UIViewController *)toVC
{
    if ([fromVC isKindOfClass:[HPNoteListViewController class]] && [toVC isKindOfClass:[HPNoteViewController class]])
    {
        HPNoteViewController *noteViewController = (HPNoteViewController*) toVC;
        HPNote *note = noteViewController.note;
        if (!note.isNew)
        {
            return YES;
        }
    }
    if ([fromVC isKindOfClass:[HPNoteViewController class]] && [toVC isKindOfClass:[HPNoteListViewController class]])
    {
        HPNoteViewController *noteViewController = (HPNoteViewController*) fromVC;
        HPNoteListViewController *listViewController = (HPNoteListViewController*) toVC;
        BOOL selected = [listViewController selectNote:noteViewController.note];
        if (selected)
        {
            return YES;
        }
    }
    return NO;
}

- (void)prepareForTransition:(UIViewController*)fromVC
{
    if ([fromVC isKindOfClass:[HPNoteViewController class]])
    {
        HPNoteViewController *noteViewController = (HPNoteViewController*) fromVC;
        noteViewController.willTransitionToList = YES;
    }
}

#pragma mark - Private

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

    UIView *backgroundView = [self coverView:toViewController.view rect:toViewController.view.bounds color:[UIColor whiteColor] context:transitionContext];
    [transitionContext.containerView bringSubviewToFront:toViewController.view];
    [transitionContext.containerView bringSubviewToFront:fromViewController.view];
    
    UIView *cellCover = [self coverView:cell rect:cell.bounds color:[UIColor whiteColor] context:transitionContext];
    UIView *titleLabelPlaceholder = [self fakeView:cell.titleLabel rect:cell.titleLabel.bounds context:transitionContext];
    UIView *bodyLabelPlaceholder = [self fakeView:cell.bodyLabel rect:cell.bodyLabel.bounds context:transitionContext];
    UIView *detailLabelPlaceholder = nil;
    UILabel *detailLabel = cell.detailLabel;
    if (detailLabel != nil && !detailLabel.hidden && detailLabel.text.length > 0)
    {
        detailLabelPlaceholder = [self fakeView:detailLabel rect:detailLabel.bounds context:transitionContext];
    }
    
    UITextView *noteTextView = toViewController.noteTextView;
    toViewController.view.alpha = 0;
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    NSTimeInterval firstDuration = duration * 2.0/3.0;
    NSTimeInterval secondDuration = duration - firstDuration;
    [UIView animateWithDuration:firstDuration animations:^{
        CGPoint titleOrigin = [self originForLabel:cell.titleLabel inTextView:noteTextView context:transitionContext];
        CGPoint bodyOrigin = [self originForLabel:cell.bodyLabel inTextView:noteTextView context:transitionContext];
        UILabel *detailLabel = toViewController.detailLabel;
        if (detailLabelPlaceholder)
        {
            CGPoint detailOrigin = [transitionContext.containerView convertPoint:detailLabel.bounds.origin fromView:detailLabel];
            detailLabelPlaceholder.frame = CGRectMake(detailLabelPlaceholder.frame.origin.x, detailOrigin.y, detailLabelPlaceholder.frame.size.width, detailLabelPlaceholder.frame.size.height);
        }
        titleLabelPlaceholder.frame = CGRectMake(titleOrigin.x, titleOrigin.y, titleLabelPlaceholder.frame.size.width, titleLabelPlaceholder.frame.size.height);
        bodyLabelPlaceholder.frame = CGRectMake(bodyOrigin.x, bodyOrigin.y, bodyLabelPlaceholder.frame.size.width, bodyLabelPlaceholder.frame.size.height);
        fromViewController.view.alpha = 0;
    } completion:^(BOOL finished) {
        [cellCover removeFromSuperview];
        [UIView animateWithDuration:secondDuration animations:^{
            titleLabelPlaceholder.alpha = 0;
            bodyLabelPlaceholder.alpha = 0;
            detailLabelPlaceholder.alpha = 0;
            toViewController.view.alpha = 1;
        } completion:^(BOOL finished) {
            [backgroundView removeFromSuperview];
            [titleLabelPlaceholder removeFromSuperview];
            [bodyLabelPlaceholder removeFromSuperview];
            [detailLabelPlaceholder removeFromSuperview];
            [transitionContext completeTransition:YES];
            fromViewController.view.alpha = 1;
        }];
    }];
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext fromDetail:(HPNoteViewController*)fromViewController toList:(HPNoteListViewController*)toViewController
{
    UIView *containerView = transitionContext.containerView;
    [containerView addSubview:toViewController.view];
    toViewController.view.frame = [transitionContext finalFrameForViewController:toViewController];
    
    UIView *backgroundView = [self coverView:toViewController.view rect:toViewController.view.bounds color:[UIColor whiteColor] context:transitionContext];
    [containerView bringSubviewToFront:toViewController.view];
    [containerView bringSubviewToFront:fromViewController.view];

    UITableView *tableView = toViewController.tableView;
    NSIndexPath *selectedIndexPath = [tableView indexPathForSelectedRow];
    if (!selectedIndexPath)
    {
        [toViewController selectNote:fromViewController.note];
        selectedIndexPath = [tableView indexPathForSelectedRow];
    }
    HPNoteTableViewCell *cell = (HPNoteTableViewCell*)[tableView cellForRowAtIndexPath:selectedIndexPath];
    
    UITextView *noteTextView = fromViewController.noteTextView;
    UILabel *titleLabel = cell.titleLabel;
    UILabel *bodyLabel = cell.bodyLabel;
    const BOOL handleBody = bodyLabel.text.length > 0;
    const CGRect titleRect = [self rectForLabel:titleLabel inTextView:noteTextView];
    UIView *titleCover = [self coverView:noteTextView rect:titleRect color:[UIColor whiteColor] context:transitionContext];

    CGRect bodyRect;
    UIView *bodyCover;
    if (handleBody)
    {
        bodyRect = [self rectForLabel:bodyLabel inTextView:noteTextView];
        bodyCover = [self coverView:noteTextView rect:bodyRect color:[UIColor whiteColor] context:transitionContext];
    }

    UIView *titlePlaceholder = [self fakeView:noteTextView rect:titleRect failsafeView:titleLabel context:transitionContext];
    
    UIView *bodyPlaceholder;
    if (handleBody)
    {
        bodyPlaceholder = [self fakeView:noteTextView rect:bodyRect failsafeView:bodyLabel context:transitionContext];
    }
    
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

#pragma mark - Utils

- (UIView*)coverView:(UIView*)view rect:(CGRect)rect color:(UIColor*)color context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIImage *image = HPImageFromColor(color, rect.size);
    UIImageView *imageView = [self addImageViewWithImage:image rect:rect fromView:view context:transitionContext];
    return imageView;
}

- (UIView*)fakeView:(UIView*)view rect:(CGRect)rect context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIImage *image = [view hp_imageFromRect:rect];
    UIImageView *imageView = [self addImageViewWithImage:image rect:rect fromView:view context:transitionContext];
    return imageView;
}

- (UIView*)fakeView:(UIView*)view rect:(CGRect)rect failsafeView:(UIView*)failsafeView context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIImage *image = [view hp_imageFromRect:rect];
    if (![self isValidImage:image])
    {
        image = [failsafeView hp_imageFromRect:failsafeView.bounds];
        rect = CGRectMake(rect.origin.x, rect.origin.y, image.size.width, image.size.height);
    }
    UIImageView *imageView = [self addImageViewWithImage:image rect:rect fromView:view context:transitionContext];
    return imageView;
}

- (UIImageView*)addImageViewWithImage:(UIImage*)image rect:(CGRect)rect fromView:(UIView*)view context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    UIView *containerView = transitionContext.containerView;
    rect = [containerView convertRect:rect fromView:view];
    imageView.frame = rect;
    [containerView addSubview:imageView];
    return imageView;
}

- (UIImage*)imageFromView:(UIView *)view
{
    return [view hp_imageFromRect:view.bounds];
}

- (BOOL)isValidImage:(UIImage*)image
{ // Checks if the first line isn't black, which is what happens when the text is not rendering due to scrolling.
    CGImageRef imageRef = image.CGImage;
    NSUInteger width = CGImageGetWidth(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, 1,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, 1), imageRef);
    CGContextRelease(context);
    
    int byteIndex = 0;
    BOOL found = NO;
    for (int i = 0 ; i < width ; ++i)
    {
        CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        byteIndex += 4;
        if (red > 0 || green > 0 || blue > 0 || alpha < 1)
        {
            found = YES;
            break;
        }
    }
    free(rawData);
    return found;
}

- (CGPoint)originForLabel:(UILabel*)label inTextView:(UITextView*)textView context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    CGRect rect = [self rectForText:label.text inTextView:textView];
    rect = [transitionContext.containerView convertRect:rect fromView:textView];
    return rect.origin;
}

- (CGRect)rectForText:(NSString*)text inTextView:(UITextView*)textView
{
    NSLayoutManager *layoutManager = textView.layoutManager;
    NSRange charRange = [textView.text rangeOfString:text];
    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:charRange actualCharacterRange:nil];
    CGRect rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textView.textContainer];
    rect = CGRectOffset(rect, textView.textContainerInset.left, textView.textContainerInset.top);
    return CGRectMake(rect.origin.x, rect.origin.y, ceil(rect.size.width), ceil(rect.size.height));
}

- (CGRect)rectForLabel:(UILabel*)label inTextView:(UITextView*)textView
{
    NSRange visibleRange = [label hp_visibleRange];
    if (visibleRange.location == NSNotFound)
    {
        visibleRange = [textView.text lineRangeForRange:NSMakeRange(0, 0)];
    }
    NSString *substring = label.text.length >= NSMaxRange(visibleRange) ? [label.text substringWithRange:visibleRange] : @"";
    return [self rectForText:substring inTextView:textView];
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
    NSRange visibleRange = NSMakeRange(NSNotFound, 0);
    const NSInteger max = text.length - 1;
    if (max >= 0)
    {
        NSInteger next = max;
        const CGSize labelSize = self.bounds.size;
        const CGSize maxSize = CGSizeMake(labelSize.width, CGFLOAT_MAX);
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
    }
    return visibleRange;
}

@end

@implementation UIView(Utils)

- (UIImage*)hp_imageFromRect:(CGRect)rect
{
    UIGraphicsBeginImageContextWithOptions(rect.size, self.opaque, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, -rect.origin.x, -rect.origin.y);
    [self.layer.presentationLayer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
