//
//  NSString+hp_utils.m
//  Agnes
//
//  Created by Hermes on 27/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "NSString+hp_utils.h"

@implementation NSString (hp_utils)

- (NSInteger)hp_linesWithFont:(UIFont*)font width:(CGFloat)width lineHeight:(CGFloat)lineHeight
{
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGFloat textHeight = [self boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) attributes:attributes context:nil].size.height;
    textHeight = ceil(textHeight);
    NSInteger lines = round(textHeight / lineHeight);
    return lines;
}

- (void)hp_enumerateOccurrencesOfString:(NSString*)target options:(NSStringCompareOptions)opts usingBlock:(void (^)(NSRange, BOOL *))block
{
    NSRange searchRange = NSMakeRange(0, self.length);
    BOOL stop = NO;
    while (searchRange.location < self.length && !stop)
    {
        NSRange matchRange = [self rangeOfString:target options:opts range:searchRange];
        if (matchRange.location != NSNotFound)
        {
            const NSUInteger preBlockLength = self.length;
            block(matchRange, &stop);
            const NSUInteger afterBlockLength = self.length;
            NSInteger lengthDelta = afterBlockLength - preBlockLength;
            searchRange.location = matchRange.location + matchRange.length + lengthDelta;
            searchRange.length = self.length - searchRange.location;
        } else break;
    }
}

- (NSRange)hp_extendedRangeForRange:(NSRange)range
{
    NSRange extendedRange = NSUnionRange(range, [self lineRangeForRange:NSMakeRange(range.location, 0)]);
    extendedRange = NSUnionRange(extendedRange, [self lineRangeForRange:NSMakeRange(NSMaxRange(range), 0)]);
    return extendedRange;
}

- (NSUInteger)hp_numberOfOccurencesOfString:(NSString*)target range:(NSRange)range
{
    NSString *pattern = [NSRegularExpression escapedPatternForString:target];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:kNilOptions error:nil];
    NSAssert(regex, @"Regex failed");
    return [regex numberOfMatchesInString:self options:kNilOptions range:range];
}

- (NSString*)hp_stringByAddingSorroundingSpacesToString:(NSString*)string inRange:(NSRange)range
{
    NSCharacterSet *whitespaceCharacterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    { // Add space after if needed
        NSInteger nextCharacterLocation = NSMaxRange(range);
        if (nextCharacterLocation < self.length)
        {
            unichar character = [self characterAtIndex:nextCharacterLocation];
            BOOL isWhitespace = [whitespaceCharacterSet characterIsMember:character];
            if (!isWhitespace)
            {
                string = [string stringByAppendingString:@" "];
            }
        }
    }

    { // Add space before if needed
        NSInteger previousCharacterLocation = range.location - 1;
        if (previousCharacterLocation > 0)
        {
            unichar character = [self characterAtIndex:previousCharacterLocation];
            BOOL isWhitespace = [whitespaceCharacterSet characterIsMember:character];
            if (!isWhitespace)
            {
                string = [@" " stringByAppendingString:string];
            }
        }
    }
    return string;
}

- (NSInteger)hp_wordCount
{
    __block int wordCount =0;
    NSRange range = NSMakeRange(0, self.length);
    [self enumerateSubstringsInRange:range options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        wordCount++;
    }];
    return wordCount;
}

@end
