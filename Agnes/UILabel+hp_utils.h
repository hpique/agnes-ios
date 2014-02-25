//
//  UILabel+hp_utils.h
//  Agnes
//
//  Created by Hermes on 25/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UILabel (hp_utils)

- (NSRange)hp_visibleRange;

- (NSString*)hp_visibleText;

@end
