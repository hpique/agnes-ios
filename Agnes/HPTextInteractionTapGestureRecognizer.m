//
//  HPTextInteractionTapGestureRecognizer.m
//  Agnes
//
//  Created by Hermes on 25/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPTextInteractionTapGestureRecognizer.h"
#import "UITextView+hp_utils.h"
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
    UITextView *textView = (UITextView*) self.view;
    NSTextContainer *textContainer = textView.textContainer;
    NSLayoutManager *layoutManager = textView.layoutManager;
    
    const CGPoint point = [textView hp_pointFromTouch:touch];
    NSUInteger characterIndex = [layoutManager characterIndexForPoint:point inTextContainer:textContainer fractionOfDistanceBetweenInsertionPoints:nil];
    
    if (characterIndex >= textView.text.length)
    {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }

    { // characterIndexForPoint returns the nearest character. For better accuracy, we check if the point is inside the bounding rect of the returned character index
        const NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:NSMakeRange(characterIndex, 1) actualCharacterRange:nil];
        CGRect boundingRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
        if (!CGRectContainsPoint(boundingRect, point))
        {
            self.state = UIGestureRecognizerStateFailed;
            return;
        }
    }

    _textAttachment = [textView.attributedText attribute:NSAttachmentAttributeName atIndex:characterIndex effectiveRange:&_range];
    if (_textAttachment)
    {
        return;
    }
    _textAttachment = nil;
    
    _URL = [textView.attributedText attribute:NSLinkAttributeName atIndex:characterIndex effectiveRange:&_range];
    if (_URL)
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

@end
