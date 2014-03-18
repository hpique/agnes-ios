//
//  UITextView+hp_utils.h
//  Agnes
//
//  Created by Hermes on 07/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextView (hp_utils)

- (CGPoint)hp_pointFromTouch:(UITouch*)touch;

- (CGRect)hp_rectForSubstring:(NSString*)substring;

- (CGRect)hp_rectForCharacterRange:(NSRange)charRange;

- (UITextRange*)hp_textRangeFromRange:(NSRange)range;

@end
