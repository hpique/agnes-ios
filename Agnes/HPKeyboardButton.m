//
//  HPKeyboardButton.m
//  Agnes
//
//  Created by Hermes on 21/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPKeyboardButton.h"

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
        self.backgroundColor = [UIColor whiteColor];
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        self.titleLabel.minimumScaleFactor = 0.75;
        [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }
    return self;
}

- (void)setTitle:(NSString *)title forState:(UIControlState)state
{
    [super setTitle:title forState:state];
    CGFloat fontSize = title.length == 1 ? 22 : 16;
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:fontSize];
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
    const BOOL landscape = UIInterfaceOrientationIsLandscape(interfaceOrientation);
    static CGFloat LandscapeHeight = 32;
    static CGFloat LandscapeWidth = 43;
    static CGFloat LandscapeWidescreenWidth = 47;
    static CGFloat PortraitHeight = 38;
    static CGFloat PortraitWidth = 26;
    const CGFloat height = landscape ? LandscapeHeight : PortraitHeight;
    const BOOL widescreen = fabs((double)[UIScreen mainScreen].bounds.size.height - (double)568) < DBL_EPSILON;
    const CGFloat width = landscape ? (widescreen ? LandscapeWidescreenWidth : LandscapeWidth) : PortraitWidth;
    return CGSizeMake(width, height);
}


@end
