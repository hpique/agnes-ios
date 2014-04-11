//
//  HPAgnesUIMetrics.m
//  Agnes
//
//  Created by Hermes on 04/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAgnesUIMetrics.h"

@implementation HPAgnesUIMetrics

+ (CGFloat)sideMarginForInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation width:(CGFloat)width
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        static CGFloat const MarginLandscapePhone = 40;
        static CGFloat const MarginPortraitPhone = 15;
        return UIInterfaceOrientationIsLandscape(interfaceOrientation) ? MarginLandscapePhone : MarginPortraitPhone;
    }
    else if (UIInterfaceOrientationIsLandscape(interfaceOrientation))
    { // iPad landscape
        static CGFloat const MarginSmallLandscapePad = 40;
        static CGFloat const MarginLandscapePad = 102;
        return width < 1024 ? MarginSmallLandscapePad : MarginLandscapePad;
    }
    else
    { // iPad portrait
        static CGFloat MarginSmallPortraitPad = 26;
        static CGFloat MarginPortraitPad = 77;
        return width < 768 ? MarginSmallPortraitPad : MarginPortraitPad;
    }
}

@end
