//
//  UITextView+hp_utils.m
//  Agnes
//
//  Created by Hermes on 07/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UITextView+hp_utils.h"

@implementation UITextView (hp_utils)

- (CGRect)hp_rectForSubstring:(NSString*)substring
{
    NSRange charRange = [self.text rangeOfString:substring];
    if (charRange.location == NSNotFound) return CGRectNull;
    return [self hp_rectForCharacterRange:charRange];
}

- (CGRect)hp_rectForCharacterRange:(NSRange)charRange
{
    NSLayoutManager *layoutManager = self.layoutManager;
    NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:charRange actualCharacterRange:nil];
    [layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, charRange.location)];
    CGRect rect = [layoutManager boundingRectForGlyphRange:glyphRange inTextContainer:self.textContainer];
    rect = CGRectOffset(rect, self.textContainerInset.left, self.textContainerInset.top);
    return CGRectMake(rect.origin.x, rect.origin.y, ceil(rect.size.width), ceil(rect.size.height));
}

- (UITextRange*)hp_textRangeFromRange:(NSRange)range
{
    UITextPosition *beginning = self.beginningOfDocument;
    UITextPosition *start = [self positionFromPosition:beginning offset:range.location];
    UITextPosition *end = [self positionFromPosition:start offset:range.length];
    UITextRange *textRange = [self textRangeFromPosition:start toPosition:end];
    return textRange;
}

@end
