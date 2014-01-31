// HPImageViewController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HPImageViewControllerDelegate;

// Allows the user to view an image in full screen and double tap to zoom it.
// The view controller can be dismissed with a single tap.
@interface HPImageViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong, nonatomic, readonly) UIImage *image;

@property (weak, nonatomic) id<HPImageViewControllerDelegate> delegate;

- (id)initWithImage:(UIImage *)image;

@end

@protocol HPImageViewControllerDelegate <NSObject>
@optional
- (void)imageViewControllerDidDismiss:(HPImageViewController*)imageViewController;

@end
