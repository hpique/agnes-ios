//
//  HPNoteListSearchBar.m
//  Agnes
//
//  Created by Hermes on 29/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteListSearchBar.h"
#import "AGNUIMetrics.h"

@implementation HPNoteListSearchBar

- (void)layoutSubviews
{
    [super layoutSubviews];
    UIView *textField = [self findInView:self viewOfClass:[UITextField class]];
    if (textField)
    {
        const UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
        const CGFloat width = self.frame.size.width;
        const CGFloat sideMargin = [AGNUIMetrics sideMarginForInterfaceOrientation:interfaceOrientation width:width];
        const CGRect textFieldFrame = [self convertRect:textField.bounds fromView:textField];
        const CGFloat preferredWidth = width - sideMargin * 2;
        const CGFloat adjustedWidth = textFieldFrame.size.width - sideMargin + textFieldFrame.origin.x;
        const CGFloat textFieldWidth = MIN(preferredWidth, adjustedWidth);
        textField.frame = CGRectMake(sideMargin, textFieldFrame.origin.y, textFieldWidth, textFieldFrame.size.height);
    }
}

#pragma mark - Private

- (UIView*)findInView:(UIView*)view viewOfClass:(Class)class
{
    for (UIView *subview in view.subviews)
    {
        if ([subview isKindOfClass:class]) return subview;
        UIView *foundView = [self findInView:subview viewOfClass:class];
        if (foundView) return foundView;
    }
    return nil;
}

@end
