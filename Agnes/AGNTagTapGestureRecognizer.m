//
//  AGNTagTapGestureRecognizer.m
//  Agnes
//
//  Created by Hermés Piqué on 17/03/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNTagTapGestureRecognizer.h"
#import "HPNote+Detail.h"
#import "UITextView+hp_utils.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation AGNTagTapGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if (self.state == UIGestureRecognizerStateFailed) return;
    
    UITouch *touch = [touches anyObject];
    UITextView *textView = (UITextView*) self.view;
    const CGPoint point = [textView hp_pointFromTouch:touch];
    
    NSLayoutManager *layoutManager = textView.layoutManager;
    NSTextContainer *textContainer = textView.textContainer;
    NSUInteger characterIndex = [layoutManager characterIndexForPoint:point inTextContainer:textContainer fractionOfDistanceBetweenInsertionPoints:nil];
    NSString *text = textView.text;
    if (characterIndex >= text.length)
    {
        self.state = UIGestureRecognizerStateFailed;
        return;
    }
    
    const NSRange range = NSMakeRange(characterIndex, 1);
    NSRange foundRange;
    NSString *tagName = [text hp_tagInRange:range enclosing:YES tagRange:&foundRange];
    if (tagName && ![tagName isEqualToString:HPNoteTagEscapeString])
    {

        const NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:range actualCharacterRange:nil];
        CGRect boundingRect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:textContainer];
        if (CGRectContainsPoint(boundingRect, point))
        {
            _tagRange = foundRange;
            _tagRect = boundingRect;
            return;
        }
    }

    _tagRange = NSMakeRange(NSNotFound, 0);
    _tagRect = CGRectZero;
    self.state = UIGestureRecognizerStateFailed;
}

@end
