//
//  UIColor+hp_utils.h
//  Agnes
//
//  Created by Hermes on 31/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (hp_utils)

- (UIColor *)hp_lighterColor;

/**
 * Calculate relative luminance in sRGB colour space for use in WCAG 2.0 compliance
 * @link http://www.w3.org/TR/WCAG20/#relativeluminancedef
 */
- (CGFloat)hp_luminance;

@end
