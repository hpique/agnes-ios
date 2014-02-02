// HPImageViewController.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPImageViewController.h"

@interface HPImageViewController ()

@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *singleTapGestureRecognizer;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@end

@implementation HPImageViewController

- (id)initWithImage:(UIImage *)image {
    if (self = [super init]) {
        _image = image;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.singleTapGestureRecognizer requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];
    self.imageView.image = self.image;
    self.toolbar.items = self.toolbarItems;
    [self layoutToolbarForInterfaceOrientation:self.interfaceOrientation];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self layoutToolbarForInterfaceOrientation:toInterfaceOrientation];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

#pragma mark - Private

- (IBAction)handleSingleTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(imageViewControllerDidDismiss:)])
        {
            [self.delegate imageViewControllerDidDismiss:self];
        }
    }];
}

- (IBAction)handleDoubleTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.scrollView.zoomScale == self.scrollView.minimumZoomScale) {
        // Zoom in
        CGPoint center = [tapGestureRecognizer locationInView:self.scrollView];
        CGSize size = CGSizeMake(self.scrollView.bounds.size.width / self.scrollView.maximumZoomScale,
                                 self.scrollView.bounds.size.height / self.scrollView.maximumZoomScale);
        CGRect rect = CGRectMake(center.x - (size.width / 2.0), center.y - (size.height / 2.0), size.width, size.height);
        [self.scrollView zoomToRect:rect animated:YES];
    }
    else {
        // Zoom out
        [self.scrollView zoomToRect:self.scrollView.bounds animated:YES];
    }
}

- (void)layoutToolbarForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    const BOOL landscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    const BOOL phone = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
    static CGFloat toolbarHeightDefault = 44;
    static CGFloat toolbarHeightLandscapePhone = 32;
    const CGFloat height = landscape && phone ? toolbarHeightLandscapePhone : toolbarHeightDefault;
    const CGRect bounds = self.view.bounds;
    self.toolbar.frame = CGRectMake(0, bounds.size.height - height, bounds.size.width, height);
}

@end
