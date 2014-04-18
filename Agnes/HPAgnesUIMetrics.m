//
//  HPAgnesUIMetrics.m
//  Agnes
//
//  Created by Hermes on 04/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAgnesUIMetrics.h"

CGFloat const AGNIndexWidthPad = 280;

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
        
        const CGFloat ratio = (width - (1024 - AGNIndexWidthPad)) / AGNIndexWidthPad;
        const CGFloat margin = (MarginLandscapePad - MarginSmallLandscapePad) * ratio;
        return MAX(MarginSmallLandscapePad, MIN(MarginLandscapePad, margin));
    }
    else
    { // iPad portrait
        static CGFloat MarginSmallPortraitPad = 26;
        static CGFloat MarginPortraitPad = 77;

        const CGFloat ratio = (width - (768 - AGNIndexWidthPad)) / AGNIndexWidthPad;
        const CGFloat margin = (MarginPortraitPad - MarginSmallPortraitPad) * ratio;
        return MAX(MarginSmallPortraitPad, MIN(MarginPortraitPad, margin));
    }
}

@end
