//  HPImageZoomAnimationController.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HPImageZoomTransitionDelegate;

@interface HPImageZoomAnimationController : NSObject <UIViewControllerAnimatedTransitioning>

- (id)initWithImageView:(UIImageView *)referenceImageView;

- (id)initWithImage:(UIImage*)image;

@property (nonatomic, strong) UIColor *coverColor;

@property (nonatomic, weak) id<HPImageZoomTransitionDelegate> delegate;

@end

@protocol HPImageZoomTransitionDelegate <NSObject>

@optional

- (CGRect)imageZoomTransition:(HPImageZoomAnimationController*)transition rectInView:(UIView*)view;

@end
