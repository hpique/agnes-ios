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
#import "HPNoteNavigationController.h"
#import "HPNote.h"
#import "HPNote+Thumbnail.h"
#import "HPAttachment.h"
#import "UIImage+hp_utils.h"
#import "UITextView+hp_utils.h"
#import "PSPDFTextView.h"

@interface UIView(Utils)

- (UIImage*)hp_imageFromRect:(CGRect)rect;

@end

@interface UILabel(Utils)

- (NSRange)hp_visibleRange;

@end

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

#pragma mark - Private

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext fromList:(HPNoteListViewController*)fromViewController toDetail:(HPNoteViewController*)toViewController
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
    const CGRect titleRect = [self rectForLabel:titleLabel inTextView:noteTextView context:transitionContext];
    if (!CGRectIsNull(titleRect))
    {
        titleLabelCover = [self coverView:titleLabel rect:titleLabel.bounds color:[UIColor whiteColor] context:transitionContext];
        titleLabelPlaceholder = [self fakeView:titleLabel rect:titleLabel.bounds context:transitionContext];
    }
    
    UILabel *bodyLabel = cell.bodyLabel;
    UIView *bodyLabelCover = nil;
    UIView *bodyLabelPlaceholder = nil;
    const CGRect bodyRect = [self rectForLabel:bodyLabel inTextView:noteTextView context:transitionContext];
    if (!CGRectIsNull(bodyRect))
    {
        bodyLabelCover = [self coverView:bodyLabel rect:bodyLabel.bounds color:[UIColor whiteColor] context:transitionContext];
        bodyLabelPlaceholder = [self fakeView:bodyLabel rect:bodyLabel.bounds context:transitionContext];
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
        NSTextAttachment *attachment = [noteTextView.attributedText attribute:NSAttachmentAttributeName atIndex:thumbnailCharacterIndex effectiveRange:nil];
        thumbnailViewPlaceholder = [self addImageViewWithImage:attachment.image rect:thumbnailView.bounds fromView:thumbnailView context:transitionContext];
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

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext fromDetail:(HPNoteViewController*)fromViewController toList:(HPNoteListViewController*)toViewController
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

#pragma mark - Utils

- (UIView*)coverView:(UIView*)view rect:(CGRect)rect color:(UIColor*)color context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    UIImage *image = [UIImage hp_imageWithColor:color size:rect.size];
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
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.clipsToBounds = YES;
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

- (CGRect)rectForLabel:(UILabel*)label inTextView:(UITextView*)textView context:(id <UIViewControllerContextTransitioning>)transitionContext
{
    NSRange visibleRange = [label hp_visibleRange];
    if (visibleRange.location == NSNotFound)
    {
        visibleRange = [textView.text lineRangeForRange:NSMakeRange(0, 0)];
    }
    NSString *substring = label.text.length >= NSMaxRange(visibleRange) ? [label.text substringWithRange:visibleRange] : @"";
    CGRect rect = [textView hp_rectForSubstring:substring];
    if (CGRectIsNull(rect)) return rect;
    rect = [transitionContext.containerView convertRect:rect fromView:textView];
    return rect;
}

- (CGRect)rectForLabel:(UILabel*)label inTextView:(UITextView*)textView
{
    NSRange visibleRange = [label hp_visibleRange];
    if (visibleRange.location == NSNotFound)
    {
        visibleRange = [textView.text lineRangeForRange:NSMakeRange(0, 0)];
    }
    NSString *substring = label.text.length >= NSMaxRange(visibleRange) ? [label.text substringWithRange:visibleRange] : @"";
    return [textView hp_rectForSubstring:substring];
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
    static CGFloat tolerance = 3.0f;
    
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
            CGRect boundingRect = [substring boundingRectWithSize:maxSize
                                                      options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                   attributes:attributes
                                                      context:nil];
            const CGSize boundingSize = CGSizeMake(ceil(boundingRect.size.width), ceil(boundingRect.size.height));
            if ((boundingSize.width - labelSize.width <= tolerance) && (boundingSize.height - labelSize.height <= tolerance))
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
