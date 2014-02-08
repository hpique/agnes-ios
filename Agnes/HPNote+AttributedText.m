//
//  HPNote+AttributedText.m
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote+AttributedText.h"
#import "HPAttachment.h"
#import "HPFontManager.h"
#import "HPAttachmentManager.h"
#import "NSString+hp_utils.h"
#import "UIImage+hp_utils.h"

@implementation HPAnimatedTextAttachment

- (void)setAnimating:(BOOL)animating
{
    if (_animating != _animating) return;
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

@interface HPNoteImageCache : NSObject

- (UIImage*)imageForAttachment:(HPAttachment*)attachment maxSize:(CGSize)maxSize;

@end

@implementation HPNoteImageCache {
    NSCache *_cache;
}

- (id)init
{
    if (self = [super init])
    {
        _cache = [[NSCache alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(attachmentsDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPAttachmentManager sharedManager]];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPAttachmentManager sharedManager]];
}

+ (HPNoteImageCache*)sharedCache
{
    static HPNoteImageCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPNoteImageCache alloc] init];
    });
    return instance;
}

- (UIImage*)imageForAttachment:(HPAttachment*)attachment maxSize:(CGSize)maxSize
{
    UIImage *image = attachment.image;
    UIImage *scaledImage = [_cache objectForKey:attachment.objectID];
    if (!scaledImage || scaledImage.size.width > maxSize.width || scaledImage.size.height > maxSize.height)
    {
        CGSize scaledImageSize = [image hp_aspectFitRectForSize:maxSize].size;
        scaledImage = [image hp_imageByScalingToSize:scaledImageSize];
        [_cache setObject:scaledImage forKey:attachment.objectID];
    }
    return scaledImage;
}

- (void)attachmentsDidChangeNotification:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSSet *deleted = [userInfo objectForKey:NSDeletedObjectsKey];
    for (HPAttachment *attachment in deleted)
    {
        [_cache removeObjectForKey:attachment.objectID];
    }
}

@end

@implementation HPNote (AttributedText)

- (NSAttributedString*)attributedTextForWidth:(CGFloat)width
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
        NSDictionary *attributes = [self attributesForAttachment:attachment maxWidth:width];
        [attributedString setAttributes:attributes range:matchRange];
        index++;
    }];
    return attributedString;
}

- (NSDictionary*)attributesForAttachment:(HPAttachment*)attachment maxWidth:(CGFloat)maxWidth
{
    CGSize maxSize = [self sizeForAttachmentMode:attachment.mode maxWidth:maxWidth];
    UIImage *scaledImage = [[HPNoteImageCache sharedCache] imageForAttachment:attachment maxSize:maxSize];
    
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



