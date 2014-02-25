//
//  HPTextInteractionTapGestureRecognizer.m
//  Agnes
//
//  Created by Hermes on 25/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPTextInteractionTapGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation HPTextInteractionTapGestureRecognizer {
    NSURL *_URL;
    NSTextAttachment *_textAttachment;
    NSRange _range;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if (self.state == UIGestureRecognizerStateFailed) return;

    UITouch *touch = [touches anyObject];
    CGFloat fraction = 0;
    NSUInteger characterIndex = [self characterIndexAtTouch:touch fraction:&fraction];
    
    UITextView *textView = (UITextView*) self.view;
    if (characterIndex >= textView.text.length)
    {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }

    _textAttachment = [textView.attributedText attribute:NSAttachmentAttributeName atIndex:characterIndex effectiveRange:&_range];
    if (_textAttachment && fraction < 1)
    {
        return;
    }
    _textAttachment = nil;
    
    _URL = [textView.attributedText attribute:NSLinkAttributeName atIndex:characterIndex effectiveRange:&_range];
    if (_URL && fraction < 1)
    {
        return;
    }
    _URL = nil;
    
    self.state = UIGestureRecognizerStateFailed;
    return;
}

- (void)setState:(UIGestureRecognizerState)state
{
    [super setState:state];
    if (state == UIGestureRecognizerStateRecognized)
    {
        if (_textAttachment)
        {
            if ([self.delegate respondsToSelector:@selector(gestureRecognizer:handleTapOnTextAttachment:inRange:)])
            {
                [self.delegate gestureRecognizer:self handleTapOnTextAttachment:_textAttachment inRange:_range];
            }
            _textAttachment = nil;
        }
        if (_URL)
        {
            if ([self.delegate respondsToSelector:@selector(gestureRecognizer:handleTapOnURL:inRange:)])
            {
                [self.delegate gestureRecognizer:self handleTapOnURL:_URL inRange:_range];
            }
            _URL = nil;
        }
    }
    else
    {
        _textAttachment = nil;
        _URL = nil;
    }
}

- (NSUInteger)characterIndexAtTouch:(UITouch*)touch fraction:(CGFloat*)fraction
{
    UITextView *textView = (UITextView*) self.view;
    NSLayoutManager *layoutManager = textView.layoutManager;
    CGPoint location = [touch locationInView:textView];
    location.x -= textView.textContainerInset.left;
    location.y -= textView.textContainerInset.top;
    
    NSUInteger characterIndex;
    // When an attachment or url are the last elements, the fraction tells us if the location is outside the image
    characterIndex = [layoutManager characterIndexForPoint:location inTextContainer:textView.textContainer fractionOfDistanceBetweenInsertionPoints:fraction];
    return characterIndex;
}


@end
