//
//  UIView+hp_utils.m
//  Agnes
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UIView+hp_utils.h"

typedef void (^HPKeyboardAnimationCompletionBlock)(BOOL);

@implementation UIView (hp_utils)

- (void)hp_animateWithKeyboardNotification:(NSNotification*)notification animations:(void(^)())animations completion:(HPKeyboardAnimationCompletionBlock)completion
{
    NSDictionary *info = notification.userInfo;
    NSTimeInterval duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve animationCurve = [[info objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    // We can't use animateWithDuration:delay:options:animations:completion because animationCurve has no UIViewAnimationOptions equivalent in iOS 7. See: http://stackoverflow.com/a/19235995/143378
    [UIView beginAnimations:nil context:(__bridge void*)completion];
    
    [UIView setAnimationDuration:duration];
    if (completion)
    {
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDidStopSelector:@selector(hp_keyboardAnimationDidStop:finished:context:)];
    }
    [UIView setAnimationCurve:animationCurve];
    [UIView setAnimationBeginsFromCurrentState:YES];
    animations();
    [UIView commitAnimations];
}

- (void)hp_keyboardAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
    HPKeyboardAnimationCompletionBlock completion = (__bridge HPKeyboardAnimationCompletionBlock)context;
    if (completion)
    {
        completion([finished boolValue]);
    }

}

@end
