//  HPImageZoomAnimationController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

// Image zoom custom transition.
@interface HPImageZoomAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

// Initializes the receiver with the specified reference image view.
- (id)initWithReferenceImageView:(UIImageView *)referenceImageView;

- (id)initWithReferenceImage:(UIImage*)image view:(UIView *)view rect:(CGRect)rect;

@property (nonatomic, strong) UIColor *coverColor;

@end
