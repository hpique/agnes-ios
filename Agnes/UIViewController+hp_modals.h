//
//  UIViewController+hp_modals.h
//  Agnes
//
//  Created by Hermés Piqué on 09/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController (hp_modals)

- (BOOL)hp_dismissActionSheet:(UIActionSheet * __strong *)actionSheetRef animated:(BOOL)animated;

- (BOOL)hp_dismissPopover:(UIPopoverController * __strong *)popoverControllerRef animated:(BOOL)animated;

- (UIPopoverController*)hp_presentActivityViewController:(UIActivityViewController*)activityViewController fromBarButtonItem:(UIBarButtonItem*)barButtonItem animated:(BOOL)animated;

@end
