//
//  HPNavigationBarToggleTitleView.h
//  Agnes
//
//  Created by Hermes on 19/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPNavigationBarToggleTitleView : UIView

- (void)setTitle:(NSString*)title;

- (void)setSubtitle:(NSString*)mode animated:(BOOL)animated transient:(BOOL)transient;

@end
