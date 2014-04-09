//
//  HPKeyboardButton.m
//  Agnes
//
//  Created by Hermes on 21/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPKeyboardButton.h"

static BOOL HPIsWidescreen()
{
    const BOOL isWidescreen = fabs((double)[UIScreen mainScreen].bounds.size.height - (double)568) < DBL_EPSILON;
    return isWidescreen;
}

@implementation HPKeyboardButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 4;
        self.layer.shadowColor = [UIColor grayColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 1);
        self.layer.shadowOpacity = 1;
        self.layer.shadowRadius = 0;
        self.backgroundColor = [self.class backgroundColorForControlState:UIControlStateNormal];
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.minimumScaleFactor = 0.75;
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.backgroundColor = [self.class backgroundColorForControlState:highlighted ? UIControlStateHighlighted : UIControlStateNormal];
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    [super setTitle:title forState:state];
    
    static CGFloat const FontSizeCharacterLandscapePhone = 22;
    static CGFloat const FontSizeCharacterLandscapePad = 36;
    static CGFloat const FontSizeCharacterPortraitPhone = 22;
    static CGFloat const FontSizeCharacterPortraitPad = 28;
    static CGFloat const FontSizeWordLandscapePhone = 16;
    static CGFloat const FontSizeWordLandscapePad = 26;
    static CGFloat const FontSizeWordPortraitPhone = 16;
    static CGFloat const FontSizeWordPortraitPad = 21;
    
    const UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    const BOOL isLandscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    const BOOL isPhone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    const BOOL isWord = title.length > 1;
    
    CGFloat fontSize = isPhone ? (isLandscape ? (isWord ? FontSizeWordLandscapePhone : FontSizeCharacterLandscapePhone) : (isWord ? FontSizeWordPortraitPhone : FontSizeCharacterPortraitPhone)) : (isLandscape ? (isWord ? FontSizeWordLandscapePad : FontSizeCharacterLandscapePad) : (isWord ? FontSizeWordPortraitPad : FontSizeCharacterPortraitPad));
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:fontSize];
    [self setNeedsLayout]; // Without this the title doesn't change when cells are reused. WTF?
}

- (CGSize)intrinsicContentSize
{
    const CGSize size = [HPKeyboardButton sizeForOrientation:[UIApplication sharedApplication].statusBarOrientation];
    NSString *title = [self titleForState:UIControlStateNormal];
    if (title.length == 1)
    {
        return size;
    } else {
        CGSize superIntrinsicSize = [super intrinsicContentSize];
        return CGSizeMake(superIntrinsicSize.width, size.height);
        
    }
}

+ (CGSize)sizeForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    static CGFloat const WidthLandscapePhone = 43;
    static CGFloat const HeightLandscapePhone = 32;
    static CGFloat const WidthLandscapePad = 77;
    static CGFloat const HeightLandscapePad = 75;
    static CGFloat const WidthLandscapePhoneWidescreen = 47;
    static CGFloat const WidthPortraitPhone = 26;
    static CGFloat const HeightPortraitPhone = 38;
    static CGFloat const WidthPortraitPad = 56;
    static CGFloat const HeightPortraitPad = 58;

    const BOOL landscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    const BOOL isPhone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    const BOOL isWidescreen = HPIsWidescreen();
    
    const CGFloat height = isPhone ? (landscape ? HeightLandscapePhone : HeightPortraitPhone) : (landscape ? HeightLandscapePad : HeightPortraitPad);
    const CGFloat width = isPhone ? (landscape ? (isWidescreen ? WidthLandscapePhoneWidescreen : WidthLandscapePhone) : WidthPortraitPhone) : (landscape ? WidthLandscapePad : WidthPortraitPad);
    
    return CGSizeMake(width, height);
}

+ (CGFloat)keySeparatorForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    static CGFloat const SeparatorLandscapePhone = 5;
    static CGFloat const SeparatorLandscapePhoneWidescreen = 6;
    static CGFloat const SeparatorPortraitPhone = 6;
    static CGFloat const SeparatorLandscapePad = 14;
    static CGFloat const SeparatorPortraitPad = 12;

    const BOOL landscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    const BOOL isPhone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;

    const CGFloat separator = isPhone ? (landscape ? (HPIsWidescreen() ? SeparatorLandscapePhoneWidescreen : SeparatorLandscapePhone) : SeparatorPortraitPhone) : (landscape ? SeparatorLandscapePad : SeparatorPortraitPad);
    return separator;
}

+ (CGFloat)sideInsetForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    static CGFloat const SideInsetLandscapePhone = 3;
    static CGFloat const SideInsetLandscapeWidescreenPhone = 23;
    static CGFloat const SideInsetPortraitPhone = 3;
    static CGFloat const SideInsetLandscapePad = 7;
    static CGFloat const SideInsetPortraitPad = 6;
    
    const BOOL landscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    const BOOL isPhone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    const BOOL isWidescreen = HPIsWidescreen();
    
    const CGFloat sideInset = isPhone ? (landscape ? (isWidescreen ? SideInsetLandscapeWidescreenPhone : SideInsetLandscapePhone) : SideInsetPortraitPhone) : (landscape ? SideInsetLandscapePad : SideInsetPortraitPad);
    return sideInset;
}

+ (CGFloat)topMarginForOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    static CGFloat const HeightLandscapePhone = 4;
    static CGFloat const HeightPortraitPhone = 6;
    static CGFloat const HeightLandscapeTablet = 11;
    static CGFloat const HeightPortraitTablet = 8;

    const BOOL landscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    const BOOL isPhone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    const CGFloat separator = isPhone ? (landscape ? HeightLandscapePhone : HeightPortraitPhone) : (landscape ? HeightLandscapeTablet : HeightPortraitTablet);
    return separator;
}

#pragma mark Utils

+ (UIColor*)backgroundColorForControlState:(UIControlState)controlState
{
    switch (controlState) {
        case UIControlStateHighlighted:
            return [UIColor colorWithRed:213.0f/255.0f green:215.0f/255.0f blue:217.0f/255.0f alpha:0.99];
        default:
            return [UIColor colorWithWhite:1 alpha:0.99];
    }

}

@end
