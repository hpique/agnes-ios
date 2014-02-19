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
    UILabel *_modeLabel;
    
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
    _modeLabel = [[UILabel alloc] init];
    _modeLabel.textAlignment = NSTextAlignmentCenter;
    _modeLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self applyFonts];
    [self applyPreferences];
    
    [self addSubview:_titleLabel];
    [self addSubview:_modeLabel];
    NSDictionary *views = NSDictionaryOfVariableBindings(_titleLabel, _modeLabel);
    {
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[_titleLabel]|" options:kNilOptions metrics:nil views:views];
        [self addConstraints:constraints];
    }
    {
        NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[_modeLabel]|" options:kNilOptions metrics:nil views:views];
        [self addConstraints:constraints];
    }
    {
        NSLayoutConstraint *contraint = [NSLayoutConstraint constraintWithItem:_titleLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1 constant:0];
        [self addConstraint:contraint];
    }
    {
        NSLayoutConstraint *contraint = [NSLayoutConstraint constraintWithItem:_modeLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:_titleLabel attribute:NSLayoutAttributeBottom multiplier:1 constant:-4];
        [self addConstraint:contraint];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFontsNotification:) name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferencesNotification:) name:HPPreferencesManagerDidChangePreferencesNotification object:[HPPreferencesManager sharedManager]];
}

- (void)dealloc
{
    [_restoreTitleTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
}

#pragma mark Public

- (void)setTitle:(NSString*)title
{
    _title = title;
    _titleLabel.font = _titleFont;
    _titleLabel.text = title;
    _modeLabel.text = nil;
}

- (void)setMode:(NSString*)mode animated:(BOOL)animated
{
    [_restoreTitleTimer invalidate];
    const NSTimeInterval duration = animated ? 0.2 : 0;
    
    [UIView transitionWithView:self duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        const BOOL landscape = UIInterfaceOrientationIsLandscape(orientation);
        if (landscape)
        {
            _titleLabel.font = [_titleFont fontWithSize:_titleFont.pointSize * 0.75];
            _titleLabel.text = mode;
            _modeLabel.text = nil;
        }
        else
        {
            _titleLabel.font = _titleFont;
            _titleLabel.text = _title;
            _modeLabel.text = mode;
        }
    } completion:^(BOOL finished) {}];
    _restoreTitleTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(restoreTitleFromTimer:) userInfo:nil repeats:NO];
}

#pragma mark Private

- (void)applyFonts
{
    HPFontManager *fonts = [HPFontManager sharedManager];
    _titleFont = fonts.fontForNavigationBarTitle;
    _titleLabel.font = _titleFont;
    _modeLabel.font = fonts.fontForNavigationBarDetail;
}

- (void)applyPreferences
{
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    UIColor *barForegroundColor = preferences.barForegroundColor;
    _titleLabel.textColor = barForegroundColor;
    _modeLabel.textColor = barForegroundColor;
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
