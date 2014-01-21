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
    NSString *title = [self titleForState:UIControlStateNormal];
    if (title.length == 1)
    {
        return CGSizeMake(26, 38);
    } else {
        CGSize size = [super intrinsicContentSize];
        return CGSizeMake(size.width, 38);
    }
}

@end
