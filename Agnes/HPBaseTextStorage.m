//
//  HPBaseTextStorage.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPBaseTextStorage.h"
#import "HPNote.h"
#import "HPAttachment.h"
#import "HPNote+AttributedText.h"
#import "HPFontManager.h"
#import "HPPreferencesManager.h"
#import <MessageUI/MessageUI.h>
#import "UIColor+hp_utils.h"
#import "NSString+hp_utils.h"

@implementation HPBaseTextStorage {
    NSMutableAttributedString *_backingStore;
    BOOL _needsUpdate;
}

- (id)init
{
    if (self = [super init])
    {
        _backingStore = [NSMutableAttributedString new];
    }
    return self;
}

- (NSString *)string
{
    return [_backingStore string];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
    return [_backingStore attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)str
{
    _needsUpdate = YES;
    [_backingStore replaceCharactersInRange:range withString:str];
    [self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:range changeInLength:str.length - range.length];
}

- (void)setAttributes:(NSDictionary *)attrs range:(NSRange)range
{
    [_backingStore setAttributes:attrs range:range];
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
}

- (void)processEditing
{
    if (_needsUpdate)
    {
        [_backingStore beginEditing];
        _needsUpdate = NO;
        NSRange extendedRange = [_backingStore.string hp_extendedRangeForRange:self.editedRange];
        [self addLinksInRange:extendedRange];
        [self styleParagraphs];
        [self highlightTags:extendedRange];
        [self highlightSearch]; // TODO: Title is not highligted
        [_backingStore endEditing];
    }
    [super processEditing];
}

#pragma mark - Public

- (void)setSearch:(NSString *)search
{
    [self removeSearchHighlights];
    _search = search;
    [self highlightSearch];
}

- (void)beginAnimatingAttachmentAtIndex:(NSUInteger)index
{
    HPAnimatedTextAttachment *textAttachment = [_backingStore attribute:NSAttachmentAttributeName atIndex:index effectiveRange:nil];
    textAttachment.animating = YES;
    [self edited:NSTextStorageEditedAttributes range:NSMakeRange(index, 1) changeInLength:0];
}

- (void)endAnimatingAttachmentAtIndex:(NSUInteger)index
{
    HPAnimatedTextAttachment *textAttachment = [_backingStore attribute:NSAttachmentAttributeName atIndex:index effectiveRange:nil];
    textAttachment.animating = NO;
    [self edited:NSTextStorageEditedAttributes range:NSMakeRange(index, 1) changeInLength:0];
}

- (void)setAnimationProgress:(CGFloat)progress ofAttachmentAtIndex:(NSUInteger)index
{
    HPAnimatedTextAttachment *textAttachment = [_backingStore attribute:NSAttachmentAttributeName atIndex:index effectiveRange:nil];
    textAttachment.animationProgress = progress;
    [self edited:NSTextStorageEditedAttributes range:NSMakeRange(index, 1) changeInLength:0];
}

#pragma mark - Private

- (void)addLinksInRange:(NSRange)range
{
    [_backingStore removeAttribute:NSLinkAttributeName range:range];
    
    if ([MFMailComposeViewController canSendMail])
    {
        [self addLinksInRange:range matchingDataDetectorType:NSTextCheckingTypeLink scheme:@"mailto" urlFormat:@"%@:%@" containing:@"@"];
    }
    [self addLinksInRange:range matchingDataDetectorType:NSTextCheckingTypeLink scheme:@"http" urlFormat:@"%@://%@" containing:nil];
    [self addLinksInRange:range matchingDataDetectorType:NSTextCheckingTypePhoneNumber scheme:@"tel" urlFormat:@"%@://%@" containing:nil];
}

- (void)addLinksInRange:(NSRange)range matchingDataDetectorType:(NSTextCheckingType)type scheme:(NSString*)scheme urlFormat:(NSString*)format containing:(NSString*)extra
{
    NSError *error = nil;
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:type error:&error];
    NSAssert(detector, @"Data detector error %@", error);
    NSString *text = _backingStore.string;
    [detector enumerateMatchesInString:text options:kNilOptions range:range usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop)
     {
         NSRange resultRange = result.range;
         NSURL *previousUrl = [_backingStore attribute:NSLinkAttributeName atIndex:resultRange.location effectiveRange:nil];
         if (previousUrl) return;
         
         NSString *substring = [text substringWithRange:resultRange];
         if (extra != nil && [substring rangeOfString:extra].location == NSNotFound) return;

         if (![substring hasPrefix:scheme])
         {
             substring = [NSString stringWithFormat:format, scheme, [substring stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
         }
         NSURL *url = [NSURL URLWithString:substring];
         [_backingStore addAttribute:NSLinkAttributeName value:url range:resultRange];
     }];
}

/** Bold first line and center attachments.
 */
- (void)styleParagraphs
{
    UIFont *bodyFont = [[HPFontManager sharedManager] fontForNoteBody];
    UIFont *titleFont = [[HPFontManager sharedManager] fontForNoteTitle];

    NSRange range = NSMakeRange(0, _backingStore.string.length);
    __block NSInteger paragraphIndex = 0;
    
    [_backingStore.string enumerateSubstringsInRange:range options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        NSString *trimmed = [substring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        trimmed = [trimmed stringByReplacingOccurrencesOfString:[HPNote attachmentString] withString:@""];
        // Skip first empty lines, if any
        if (paragraphIndex != 0 || trimmed.length > 0)
        {
            UIFont *font = paragraphIndex == 0 && ![self.tag isEqualToString:trimmed] ? titleFont : bodyFont;
            [_backingStore addAttribute:NSFontAttributeName value:font range:enclosingRange];
            paragraphIndex++;
        }

        NSParagraphStyle *paragraphStyle = [HPNote paragraphStyleOfAttributedText:_backingStore paragraphRange:substringRange];
        [_backingStore addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:enclosingRange];
    }];
}

- (void)highlightTags:(NSRange)changedRange
{
    NSRegularExpression* regex = [HPNote tagRegularExpression];
    UIColor *color = [HPPreferencesManager sharedManager].tintColor;
    NSDictionary* attributes = @{ NSForegroundColorAttributeName : color };
    
    [self removeAttribute:NSForegroundColorAttributeName range:changedRange];
    
    [regex enumerateMatchesInString:_backingStore.string
                            options:0
                              range:changedRange
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
    {
        NSRange matchRange = [match rangeAtIndex:0];
        [self addAttributes:attributes range:matchRange];
    }];
}

- (void)highlightSearch
{
    if (!self.search) return;
    NSString *text = self.string;
    NSRange searchRange = NSMakeRange(0, text.length);
    NSString *pattern = [NSRegularExpression escapedPatternForString:self.search];
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    UIColor *color = [HPPreferencesManager sharedManager].tintColor;
    color = [color hp_lighterColor];
    NSDictionary* attributes = @{ NSBackgroundColorAttributeName : color};
    
    [regex enumerateMatchesInString:text
                            options:0
                              range:searchRange
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
     {
         NSRange matchRange = [match rangeAtIndex:0];
         [self addAttributes:attributes range:matchRange];
     }];
}

- (void)removeSearchHighlights
{
    if (!self.search) return;
    NSString *text = self.string;
    NSRange searchRange = NSMakeRange(0, text.length);
    NSString *pattern = [NSRegularExpression escapedPatternForString:self.search];
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    [regex enumerateMatchesInString:text
                            options:0
                              range:searchRange
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
     {
         NSRange matchRange = [match rangeAtIndex:0];
         [self removeAttribute:NSBackgroundColorAttributeName range:matchRange];
     }];
}

@end
