//
//  AGNTypingController.m
//  Agnes
//
//  Created by Hermés Piqué on 08/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNTypingController.h"
#import "AGNPreferencesManager.h"

static NSString *const AGNDefaultsKeyTypingSpeed = @"HPAgnesTypingSpeed";
static NSTimeInterval const AGNDefaultTypingSpeed = 0.5;

@implementation AGNTypingController {
    NSTimer *_typingTimer;
    NSDate *_typingPreviousDate;
}

- (void)setTyping:(BOOL)typing animated:(BOOL)animated
{
    _typing = typing;
    [_typingTimer invalidate];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(finishTyping) object:nil];
    if (typing)
    {
        NSDate *now = [NSDate date];
        if (_typingPreviousDate)
        {
            NSTimeInterval currentSpeed = [now timeIntervalSinceDate:_typingPreviousDate];
            static CGFloat currentSpeedWeight = 0.05;
            self.typingSpeed = self.typingSpeed * (1 - currentSpeedWeight) + currentSpeed * currentSpeedWeight;
        }
        _typingPreviousDate = now;
        
        [self hideBarsAnimated:animated];
        
        static CGFloat stopMultiplier = 5;
        static CGFloat minimumDelay = 2;
        const CGFloat typingDelay = MAX(self.typingSpeed * stopMultiplier, minimumDelay) ;
        _typingTimer = [NSTimer scheduledTimerWithTimeInterval:typingDelay target:self selector:@selector(finishTyping) userInfo:nil repeats:NO];
    }
    else
    {
        [self showBarsAnimated:animated];
    }
}

- (void)finishTyping
{
    [self setTyping:NO animated:YES];
}

#pragma mark Typing speed

- (NSTimeInterval)typingSpeed
{
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:AGNDefaultsKeyTypingSpeed];
    return value ? [value doubleValue] : AGNDefaultTypingSpeed;
}

- (void)setTypingSpeed:(NSTimeInterval)typingSpeed
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@(typingSpeed) forKey:AGNDefaultsKeyTypingSpeed];
}

#pragma mark Toggling bars

- (void)hideBarsAnimated:(BOOL)animated
{
    UINavigationController *navigationController = [self.delegate navigationControllerForTypingController:self];
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    const BOOL canHideBars = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone && UIInterfaceOrientationIsLandscape(interfaceOrientation);
    if (!navigationController.navigationBarHidden && canHideBars)
    {
        [navigationController setNavigationBarHidden:YES animated:animated];
        if (![UIApplication sharedApplication].statusBarHidden)
        {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
        }
    }
}

- (void)showBarsAnimated:(BOOL)animated
{
    UINavigationController *navigationController = [self.delegate navigationControllerForTypingController:self];
    if (navigationController.navigationBarHidden)
    {
        if ([UIApplication sharedApplication].statusBarHidden && ![AGNPreferencesManager sharedManager].statusBarHidden)
        {
            [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        }
        _typingPreviousDate = nil;
        [navigationController setNavigationBarHidden:NO animated:animated];
        [self.delegate typingController:self didShowBarsAnimated:animated];
    }

}

@end
