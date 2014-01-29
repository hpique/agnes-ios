//
//  HPNoteNavigationController.h
//  Agnes
//
//  Created by Hermes on 26/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPAgnesNavigationController.h"

@protocol HPNoteTransitionViewController

@property (nonatomic, assign) BOOL transitioning;
@property (nonatomic, assign) BOOL wantsDefaultTransition;

@end

@interface HPNoteNavigationController : HPAgnesNavigationController

@end
