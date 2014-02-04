//
//  HPAgnesUIMetrics.m
//  Agnes
//
//  Created by Hermes on 04/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAgnesUIMetrics.h"

@implementation HPAgnesUIMetrics

+ (CGFloat)sideMarginForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    static CGFloat landscapeMargin = 40;
    static CGFloat portraitMargin = 15;
    return UIInterfaceOrientationIsLandscape(interfaceOrientation) ? landscapeMargin : portraitMargin;
}

@end
