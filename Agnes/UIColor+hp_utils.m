//
//  UIColor+hp_utils.m
//  Agnes
//
//  Created by Hermes on 31/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIColor+hp_utils.h"

@implementation UIColor (hp_utils)

- (UIColor *)hp_lighterColor
{
    CGFloat h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
    {
        return [UIColor colorWithHue:h
                          saturation:s * 0.4
                          brightness:MIN(b * 1.6, 1.0)
                               alpha:a];
    }
    return self;
}

- (CGFloat)hp_luminance
{
    CGFloat rgb[3] = {0, 0, 0};
    // TODO: Consider alpha
    if (![self getRed:&(rgb[0]) green:&(rgb[1]) blue:&(rgb[2]) alpha:nil]) return 0;
    
    for (int i = 0; i < 3; i++)
    {
        CGFloat v = rgb[i];
        if (v <= 0.03928)
        {
           rgb[i] = v / 12.92;
        }
        else
        {
            rgb[i] = pow(((v + 0.055) / 1.055), 2.4);
        }
    }
    //Calculate relative luminance using ITU-R BT. 709 coefficients
    return (rgb[0] * 0.2126) + (rgb[1] * 0.7152) + (rgb[2] * 0.0722);
}

@end
