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

@end
