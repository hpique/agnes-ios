//
//  UIImage+hp_utils.h
//  Agnes
//
//  Created by Hermes on 30/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (hp_utils)

- (CGRect)hp_aspectFillRectForSize:(CGSize)size;

- (CGRect)hp_aspectFitRectForSize:(CGSize)size;

- (UIImage*)hp_imageByRoundingCornersWithRadius:(float)radius;

- (UIImage *)hp_imageByScalingToSize:(CGSize)newSize;

+ (UIImage*)hp_imageWithColor:(UIColor*)color size:(CGSize)size;


@end
