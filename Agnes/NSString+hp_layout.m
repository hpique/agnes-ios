//
//  NSString+hp_layout.m
//  Agnes
//
//  Created by Hermes on 27/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "NSString+hp_layout.h"

@implementation NSString (hp_layout)

- (NSInteger)hp_linesWithFont:(UIFont*)font width:(CGFloat)width lineHeight:(CGFloat*)lineHeight
{
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGFloat textHeight = [self boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) attributes:attributes context:nil].size.height;
    *lineHeight = [@"" boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) attributes:attributes context:nil].size.height;
    NSInteger lines = round(textHeight / *lineHeight);
    return lines;
}

@end
