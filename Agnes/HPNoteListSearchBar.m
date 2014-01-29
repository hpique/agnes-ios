//
//  HPNoteListSearchBar.m
//  Agnes
//
//  Created by Hermes on 29/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteListSearchBar.h"

@implementation HPNoteListSearchBar {
    BOOL _searching;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initHelper];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initHelper];
}

- (void)initHelper
{
    _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self addSubview:_actionButton];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (_searching) return;
    UIView *textField = [self findInView:self viewOfClass:[UITextField class]];
    if (textField)
    {
        CGRect frame = [self convertRect:textField.bounds fromView:textField];
        _actionButton.center = textField.center;
        CGRect buttonFrame = _actionButton.frame;
        CGFloat textFieldWidth = frame.size.width - buttonFrame.size.width - frame.origin.x;
        textField.frame = CGRectMake(frame.origin.x, frame.origin.y, textFieldWidth, frame.size.height);
        _actionButton.frame = CGRectMake(frame.origin.x + textFieldWidth + frame.origin.x, buttonFrame.origin.y, buttonFrame.size.width, buttonFrame.size.height);
    }
}

#pragma mark - Public

- (void)setWillBeginSearch
{
    _searching = YES;
    _actionButton.alpha = 1;
    [UIView animateWithDuration:0.3 animations:^{
        _actionButton.alpha = 0;
    }];
}

- (void)setWillEndSearch
{
    _searching = NO;
    _actionButton.alpha = 0;
    [UIView animateWithDuration:0.3 animations:^{
        _actionButton.alpha = 1;
    }];
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
