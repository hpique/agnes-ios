//
//  AGNGalleryController.m
//  Agnes
//
//  Created by Hermés Piqué on 21/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNGalleryController.h"
#import "UITextView+hp_utils.h"
#import "HPNote.h"
#import "HPAttachment.h"
#import "HPTracker.h"
#import "UIViewController+hp_modals.h"
#import <RMGallery/RMGalleryViewController.h>
#import <RMGallery/RMGalleryTransition.h>

@interface AGNGalleryController()<UIViewControllerTransitioningDelegate, RMGalleryViewControllerDelegate, RMGalleryTransitionDelegate, RMGalleryViewDataSource, UIPopoverControllerDelegate>

@end

@implementation AGNGalleryController {
    BOOL _presentedImageRemoved;
    RMGalleryViewController *_galleryViewController;
    NSUInteger _attachmentIndex;
    
    UIPopoverController *_activityPopoverController;
}

#pragma mark Public

- (void)presentAttachmentAtIndex:(NSUInteger)characterIndex;
{
    _attachmentIndex = characterIndex;
    
    _galleryViewController = [RMGalleryViewController new];
    _galleryViewController.galleryView.galleryDataSource = self;
    _galleryViewController.delegate = self;
    _galleryViewController.transitioningDelegate = self;
    _galleryViewController.toolbar.barStyle = UIBarStyleBlackTranslucent;
    
    UIBarButtonItem *trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(attachmentTrashBarButtonItemAction:)];
    UIBarButtonItem *actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(attachmentActionBarButtonItemAction:)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    _galleryViewController.toolbarItems = @[trashBarButtonItem, flexibleSpace, actionBarButtonItem];
    
    [self.viewController presentViewController:_galleryViewController animated:YES completion:nil];
}

#pragma mark Private

- (void)didDismissGalleryViewController
{
    _galleryViewController = nil;
    _presentedImageRemoved = NO;
    _activityPopoverController = nil;
}

#pragma mark RMGalleryDataSource

- (void)galleryView:(RMGalleryView*)galleryView imageForIndex:(NSUInteger)index completion:(void (^)(UIImage *image))completionBlock
{
    UIImage *image = [self imageAtCharacterIndex:_attachmentIndex];
    completionBlock(image);
}

- (NSUInteger)numberOfImagesInGalleryView:(RMGalleryView*)image
{
    return 1;
}

#pragma mark Toolbar

- (void)attachmentTrashBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self.viewController hp_dismissPopover:&_activityPopoverController animated:YES];
    
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"trash_attachment"];
    NSMutableAttributedString *attributedString = self.textView.attributedText.mutableCopy;
    [attributedString replaceCharactersInRange:NSMakeRange(_attachmentIndex, 1) withString:@""];
    self.textView.attributedText = attributedString;
    _presentedImageRemoved = YES;

    [self.delegate galleryController:self didTrashAttachmentAtIndex:_attachmentIndex];
    
    [self.viewController dismissViewControllerAnimated:YES completion:^{
        [self didDismissGalleryViewController];
    }];
}

- (void)attachmentActionBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if ([self.viewController hp_dismissPopover:&_activityPopoverController animated:YES]) return;
    
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"share_attachment"];
    UIImage *image = [self imageAtCharacterIndex:_attachmentIndex];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[image] applicationActivities:nil];
    
    _activityPopoverController = [_galleryViewController hp_presentActivityViewController:activityViewController fromBarButtonItem:barButtonItem animated:YES];
    _activityPopoverController.delegate = self;
}

#pragma mark Private

- (UIImage*)imageAtCharacterIndex:(NSUInteger)characterIndex
{
    HPAttachment *attachment = [self.textView.attributedText attribute:HPNoteAttachmentAttributeName atIndex:_attachmentIndex effectiveRange:nil];
    UIImage *image = attachment.image;
    return image;
}

#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    if ([presented isKindOfClass:RMGalleryViewController.class])
    {
        RMGalleryTransition *transition = [RMGalleryTransition new];
        transition.delegate = self;
        return transition;
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    if ([dismissed isKindOfClass:RMGalleryViewController.class])
    {
        RMGalleryTransition *transition = [RMGalleryTransition new];
        transition.delegate = self;
        return transition;
    }
    return nil;
}

#pragma mark RMGalleryViewControllerDelegate

- (void)galleryViewController:(RMGalleryViewController*)galleryViewController didDismissViewControllerAnimated:(BOOL)animated
{
    [self didDismissGalleryViewController];
}

#pragma mark RMGalleryTransitionDelegate

- (UIImage*)galleryTransition:(RMGalleryTransition*)transition transitionImageForIndex:(NSUInteger)index
{
    NSTextAttachment *attachment = [self.textView.attributedText attribute:NSAttachmentAttributeName atIndex:_attachmentIndex effectiveRange:nil];
    return attachment.image;
}

- (CGRect)galleryTransition:(RMGalleryTransition*)transition transitionRectForIndex:(NSUInteger)index inView:(UIView*)view
{
    CGRect imageRect = [self.textView hp_rectForCharacterRange:NSMakeRange(_attachmentIndex, 1)];
    if (_presentedImageRemoved)
    {
        imageRect = CGRectMake(imageRect.origin.x + imageRect.size.width / 2, imageRect.origin.y, 1, 1);
    }
    return [view convertRect:imageRect fromView:self.textView];
}

- (CGSize)galleryTransition:(RMGalleryTransition*)transition estimatedSizeForIndex:(NSUInteger)index
{
    HPAttachment *attachment = [self.textView.attributedText attribute:HPNoteAttachmentAttributeName atIndex:_attachmentIndex effectiveRange:nil];
    UIImage *image = attachment.image;
    return image.size;
}

- (UIColor*)galleryTransition:(RMGalleryTransition *)transition coverColorForIndex:(NSUInteger)index
{
    return [UIColor whiteColor];
}

#pragma mark UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    _activityPopoverController = nil;
}

@end
