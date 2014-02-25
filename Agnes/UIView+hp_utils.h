//
//  UIView+hp_utils.h
//  Agnes
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^HPKeyboardAnimationCompletionBlock)(BOOL);

@interface UIView (hp_utils)

- (void)hp_animateWithKeyboardNotification:(NSNotification*)notification animations:(void(^)())animations completion:(HPKeyboardAnimationCompletionBlock)completion;

@end
