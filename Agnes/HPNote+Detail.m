//
//  HPNote+Detail.m
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote+Detail.h"
#import "HPAttachment.h"
#import "HPTag.h"
#import "HPNoteManager.h"
#import "HPFontManager.h"
#import "HPAttachmentManager.h"
#import "HPAgnesImageCache.h"
#import "NSString+hp_utils.h"
#import "UIImage+hp_utils.h"

@implementation HPAnimatedTextAttachment

- (void)setAnimating:(BOOL)animating
{
    _animating = animating;
    if (_animating)
    {
        _animationProgress = 0;
    }
}

- (CGRect)attachmentBoundsForTextContainer:(NSTextContainer *)textContainer proposedLineFragment:(CGRect)lineFrag glyphPosition:(CGPoint)position characterIndex:(NSUInteger)charIndex
{
    if (!self.animating)
    {
        CGRect result = [super attachmentBoundsForTextContainer:textContainer proposedLineFragment:lineFrag glyphPosition:position characterIndex:charIndex];
        return result;
    }
    CGSize imageSize = self.image.size;
    CGFloat width = imageSize.width * _animationProgress;
    CGFloat height = imageSize.height * _animationProgress;
    return CGRectMake(0, 0, width, height);
}

- (UIImage *)imageForBounds:(CGRect)imageBounds textContainer:(NSTextContainer *)textContainer characterIndex:(NSUInteger)charIndex
{
    if (!self.animating)
    {
        return [super imageForBounds:imageBounds textContainer:textContainer characterIndex:charIndex];
    }
    return nil;
}

@end

@implementation HPNote (Detail)

- (NSAttributedString*)attributedText
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.text];
    __block NSInteger index = 0;
    [self.text hp_enumerateOccurrencesOfString:[HPNote attachmentString] options:kNilOptions usingBlock:^(NSRange matchRange, BOOL *stop) {
        if (index >= self.attachments.count)
        {
            *stop = YES;
            return;
        }
        HPAttachment *attachment = self.attachments[index];
        NSDictionary *attributes = [self attributesForAttachment:attachment];
        [attributedString setAttributes:attributes range:matchRange];
        index++;
    }];
    return attributedString;
}

- (NSDictionary*)attributesForAttachment:(HPAttachment*)attachment
{
    UIImage *scaledImage = [[HPAgnesImageCache sharedCache] noteDetailImageForAttachment:attachment];
    
    HPAnimatedTextAttachment *textAttachment = [[HPAnimatedTextAttachment alloc] init];
    textAttachment.image = scaledImage;
    
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    [attributes setObject:textAttachment forKey:NSAttachmentAttributeName];
    
    if (attachment.mode == HPAttachmentModeDefault)
    {
        NSMutableParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        [attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
    }
    [attributes setObject:attachment forKey:HPNoteAttachmentAttributeName];
    
    return attributes;
}

- (BOOL)isEmptyInTag:(HPTag*)tag
{
    if (self.empty) return YES;
    NSString *blankText = [HPNoteManager textOfBlankNoteWithTag:tag];
    if ([self.text isEqualToString:blankText]) return YES;
    return NO;
}

- (NSSet*)userTags
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == NO", NSStringFromSelector(@selector(isSystem))];
    NSSet *userTags = [self.cd_tags filteredSetUsingPredicate:predicate];
    return userTags;
}

+ (NSParagraphStyle*)paragraphStyleOfAttributedText:(NSAttributedString*)attributedText paragraphRange:(NSRange)paragraphRange
{
    NSMutableParagraphStyle *paragraphStyle = [NSParagraphStyle defaultParagraphStyle].mutableCopy;
    __block BOOL defaultAttachment = NO;
    [attributedText enumerateAttribute:HPNoteAttachmentAttributeName inRange:paragraphRange options:kNilOptions usingBlock:^(HPAttachment *value, NSRange range, BOOL *stop) {
        if (!value) return;
        
        if (value.mode == HPAttachmentModeDefault)
        {
            defaultAttachment = YES;
            *stop = YES;
        }
    }];
    if (defaultAttachment)
    {
        paragraphStyle.alignment = NSTextAlignmentCenter;
    }
    return paragraphStyle;
}

#pragma mark - Private

- (CGSize)sizeForAttachmentMode:(HPAttachmentMode)mode maxWidth:(CGFloat)maxWidth
{
    switch (mode) {
        case HPAttachmentModeDefault:
            return CGSizeMake(maxWidth, maxWidth);
        case HPAttachmentModeCharacter:
            return CGSizeMake(maxWidth, [HPFontManager sharedManager].noteBodyLineHeight);
    }
}

@end

@implementation NSAttributedString(HPNote)

- (NSArray*)hp_attachments
{
    NSMutableArray *attachments = [NSMutableArray array];
    [self enumerateAttribute:HPNoteAttachmentAttributeName inRange:NSMakeRange(0, self.length) options:kNilOptions usingBlock:^(id value, NSRange range, BOOL *stop) {
        if (!value) return;
        [attachments addObject:value];
    }];
    return attachments;
}

- (UIImage*)hp_imageOfFirstAttachment
{
    __block UIImage *image = nil;
    [self enumerateAttribute:HPNoteAttachmentAttributeName inRange:NSMakeRange(0, self.length) options:kNilOptions usingBlock:^(HPAttachment *attachment, NSRange range, BOOL *stop) {
        if (!attachment) return;
        if (attachment.mode != HPAttachmentModeDefault) return;
        image = attachment.image;
        *stop = YES;
    }];
    return image;
}

- (NSString*)hp_valueOfLinkWithScheme:(NSString*)scheme
{
    __block NSString *foundValue = nil;
    NSRange allRange = NSMakeRange(0, self.length);
    [self enumerateAttribute:NSLinkAttributeName inRange:allRange options:0 usingBlock:^(NSURL *value, NSRange range, BOOL *stop) {
        NSString *valueScheme = value.scheme;
        if (![valueScheme isEqualToString:scheme]) return;
        
        NSString *remove = [NSString stringWithFormat:@"%@:", scheme];
        foundValue = [value.absoluteString stringByReplacingOccurrencesOfString:remove withString:@""];
        foundValue = [foundValue stringByRemovingPercentEncoding];
        *stop = YES;
    }];
    return foundValue;
}

@end

@implementation NSString(HPNote)

- (NSString*)hp_tagInRange:(NSRange)selectedRange enclosing:(BOOL)enclosing tagRange:(NSRange*)foundRange
{
    NSRange lineRange = [self lineRangeForRange:NSMakeRange(selectedRange.location, 0)];
    NSInteger length = enclosing ? lineRange.length : NSMaxRange(selectedRange) - lineRange.location;
    NSString *line = [self substringWithRange:NSMakeRange(lineRange.location, length)];
    NSInteger cursorLocationInLine = selectedRange.location - lineRange.location;
    NSRegularExpression *regex = [HPNote tagRegularExpression];
    
    __block BOOL found = NO;
    [regex enumerateMatchesInString:line options:0 range:NSMakeRange(0, line.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        NSRange resultRange = result.range;
        if (!NSLocationInRange(cursorLocationInLine, resultRange) && NSMaxRange(resultRange) != cursorLocationInLine) return;
        
        *foundRange = resultRange;
        found = YES;
        *stop = YES;
    }];
    if (found)
    {
        NSString *tag = [line substringWithRange:*foundRange];
        *foundRange = NSMakeRange(lineRange.location + (*foundRange).location, (*foundRange).length);
        return tag;
    }
    else if (selectedRange.location > 0)
    { // Check if previous character is the tag escape string
        *foundRange = NSMakeRange(selectedRange.location - 1, 1);
        NSString *substring = [self substringWithRange:*foundRange];
        if ([substring isEqualToString:HPNoteTagEscapeString])
        {
            return HPNoteTagEscapeString;
        }
    }
    return nil;
}

- (BOOL)hp_isEmptyInTag:(HPTag*)tag
{
    NSString *editText = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (editText.length == 0) return YES;
    NSString *blankText = [HPNoteManager textOfBlankNoteWithTag:tag];
    blankText = [blankText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([editText isEqualToString:blankText]) return YES;
    return NO;
}

@end
