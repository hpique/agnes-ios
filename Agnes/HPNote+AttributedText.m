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
    
    NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
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
