//
//  UILabel+hp_utils.m
//  Agnes
//
//  Created by Hermes on 25/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UILabel+hp_utils.h"

@implementation UILabel (hp_utils)

- (NSRange)hp_visibleRange
{
    static CGFloat tolerance = 3.0f;
    
    NSString *text = self.text;
    NSRange visibleRange = NSMakeRange(NSNotFound, 0);
    const NSInteger max = text.length - 1;
    if (max >= 0)
    {
        NSInteger next = max;
        const CGSize labelSize = self.bounds.size;
        const CGSize maxSize = CGSizeMake(labelSize.width, CGFLOAT_MAX);
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = self.lineBreakMode;
        NSDictionary * attributes = @{NSFontAttributeName:self.font, NSParagraphStyleAttributeName:paragraphStyle};
        NSInteger right;
        NSInteger best = 0;
        do
        {
            right = next;
            NSRange range = NSMakeRange(0, right + 1);
            NSString *substring = [text substringWithRange:range];
            CGRect boundingRect = [substring boundingRectWithSize:maxSize
                                                          options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                                       attributes:attributes
                                                          context:nil];
            const CGSize boundingSize = CGSizeMake(ceil(boundingRect.size.width), ceil(boundingRect.size.height));
            if ((boundingSize.width - labelSize.width <= tolerance) && (boundingSize.height - labelSize.height <= tolerance))
            {
                visibleRange = range;
                best = right;
                next = right + (max - right) / 2;
            } else if (right > 0)
            {
                next = right - (right - best) / 2;
            }
        } while (next != right);
    }
    return visibleRange;
}

- (NSString*)hp_visibleText
{
    const NSRange visibleRange = [self hp_visibleRange];
    if (visibleRange.location == NSNotFound) return nil;
    NSString *substring = [self.text substringWithRange:visibleRange];
    return substring;
}

@end
