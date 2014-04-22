//
//  UIViewController+hp_modals.m
//  Agnes
//
//  Created by Hermés Piqué on 09/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIViewController+hp_modals.h"

@implementation UIViewController (hp_modals)

- (BOOL)hp_dismissActionSheet:(UIActionSheet * __strong *)actionSheetRef animated:(BOOL)animated
{
    UIActionSheet *actionSheet = *actionSheetRef;
    if (actionSheet)
    {
        [actionSheet dismissWithClickedButtonIndex:actionSheet.cancelButtonIndex animated:animated];
        *actionSheetRef = nil;
        return YES;
    }
    return NO;
}

- (BOOL)hp_dismissPopover:(UIPopoverController * __strong *)popoverControllerRef animated:(BOOL)animated
{
    UIPopoverController *popoverController = *popoverControllerRef;
    if (popoverController)
    {
        [popoverController dismissPopoverAnimated:animated];
        *popoverControllerRef = nil;
        return YES;
    }
    return NO;
}

- (UIPopoverController*)hp_presentActivityViewController:(UIActivityViewController*)activityViewController fromBarButtonItem:(UIBarButtonItem*)barButtonItem animated:(BOOL)animated
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        [self presentViewController:activityViewController animated:YES completion:nil];
        return nil;
    }
    else
    {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityViewController];
        [popoverController presentPopoverFromBarButtonItem:barButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        return popoverController;
    }
}

@end
