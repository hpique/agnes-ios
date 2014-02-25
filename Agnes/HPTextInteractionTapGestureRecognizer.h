//
//  HPTextInteractionTapGestureRecognizer.h
//  Agnes
//
//  Created by Hermes on 25/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HPTextInteractionTapGestureRecognizerDelegate<UIGestureRecognizerDelegate>

@optional

-(void)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer handleTapOnURL:(NSURL*)url inRange:(NSRange)characterRange;

-(void)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer handleTapOnTextAttachment:(NSTextAttachment*)textAttachment inRange:(NSRange)characterRange;

@end

@interface HPTextInteractionTapGestureRecognizer : UITapGestureRecognizer

@property (nonatomic, weak) id<UIGestureRecognizerDelegate, HPTextInteractionTapGestureRecognizerDelegate> delegate;

@end
