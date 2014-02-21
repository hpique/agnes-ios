//
//  HPNavigationBarToggleTitleView.m
//  Agnes
//
//  Created by Hermes on 19/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNavigationBarToggleTitleView.h"
#import "HPPreferencesManager.h"
#import "HPFontManager.h"

@implementation HPNavigationBarToggleTitleView {
    UILabel *_titleLabel;
    UILabel *_subtitleLabel;
    
    NSString *_title;
    UIFont *_titleFont;
    
    NSTimer *_restoreTitleTimer;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self initHelper];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        [self initHelper];
    }
    return self;
}

- (void)initHelper
{
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    _subtitleLabel = [[UILabel alloc] init];
    _subtitleLabel.textAlignment = NSTextAlignmentCenter;
    _subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self applyFonts];
    [self applyPreferences];
    
    [self addSubview:_titleLabel];
    [self addSubview:_subtitleLabel];
    NSDictionary *views = NSDictionaryOfVariableBindings(_titleLabel, _subtitleLabel);
    {
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[_titleLabel]|" options:kNilOptions metrics:nil views:views];
        [self addConstraints:constraints];
    }
    {
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[_subtitleLabel]|" options:kNilOptions metrics:nil views:views];
        [self addConstraints:constraints];
    }
    {
        NSLayoutConstraint *contraint = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        [self addConstraint:contraint];
    }
    {
        NSLayoutConstraint *contraint = [NSLayoutConstraint constraintWithItem:_subtitleLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_titleLabel attribute:NSLayoutAttributeBottom multiplier:1 constant:-4];
        [self addConstraint:contraint];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFontsNotification:) name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferencesNotification:) name:HPPreferencesManagerDidChangePreferencesNotification object:[HPPreferencesManager sharedManager]];
}

- (void)dealloc
{
    [_restoreTitleTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPPreferencesManagerDidChangePreferencesNotification object:[HPPreferencesManager sharedManager]];
}

#pragma mark Public

- (void)setTitle:(NSString*)title
{
    _title = title;
    _titleLabel.font = _titleFont;
    _titleLabel.text = title;
    _subtitleLabel.text = nil;
}

- (void)setSubtitle:(NSString*)subtitle animated:(BOOL)animated transient:(BOOL)transient
{
    [_restoreTitleTimer invalidate];
    const NSTimeInterval duration = animated ? 0.2 : 0;
    
    [UIView transitionWithView:self duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        const BOOL landscape = UIInterfaceOrientationIsLandscape(orientation);
        if (landscape)
        {
            if (subtitle && subtitle.length > 0)
            {
                _titleLabel.font = [_titleFont fontWithSize:_titleFont.pointSize * 0.75];
                _titleLabel.text = subtitle;
                _subtitleLabel.text = nil;
            }
            else
            {
                [self setTitle:_title];
            }
        }
        else
        {
            _titleLabel.font = _titleFont;
            _titleLabel.text = _title;
            _subtitleLabel.text = subtitle;
        }
    } completion:^(BOOL finished) {}];
    if (transient)
    {
        _restoreTitleTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(restoreTitleFromTimer:) userInfo:nil repeats:NO];
    }
}

#pragma mark Private

- (void)applyFonts
{
    HPFontManager *fonts = [HPFontManager sharedManager];
    _titleFont = fonts.fontForNavigationBarTitle;
    _titleLabel.font = _titleFont;
    _subtitleLabel.font = fonts.fontForNavigationBarDetail;
}

- (void)applyPreferences
{
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    UIColor *barForegroundColor = preferences.barForegroundColor;
    _titleLabel.textColor = barForegroundColor;
    _subtitleLabel.textColor = barForegroundColor;
}

- (void)restoreTitleFromTimer:(NSTimer*)timer
{
    [self restoreTitleAnimated:YES];
}

- (void)restoreTitleAnimated:(BOOL)animated
{
    const NSTimeInterval duration = animated ? 0.2 : 0;
    [UIView transitionWithView:self duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [self setTitle:_title];
    } completion:^(BOOL finished) {}];
}

#pragma mark Notifications

- (void)didChangeFontsNotification:(NSNotification*)notification
{
    [self applyFonts];
}

- (void)didChangePreferencesNotification:(NSNotification*)notification
{
    [self applyPreferences];
}

@end
