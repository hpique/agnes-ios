//
//  HPNoteListDetailTransitionAnimator.h
//  Agnes
//
//  Created by Hermes on 22/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPNoteListDetailTransitionAnimator : NSObject<UIViewControllerAnimatedTransitioning>

+ (BOOL)canTransitionFromViewController:(UIViewController *)fromVC
                       toViewController:(UIViewController *)toVC;

@end
