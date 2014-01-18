//
//  HPBaseTextStorage.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPBaseTextStorage.h"
#import "HPNote.h"

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
        _needsUpdate = NO;
        UIFontDescriptor *bodyFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        UIFont *bodyFont = [UIFont fontWithDescriptor:bodyFontDescriptor size:0];
        UIFontDescriptor *boldBodyFontDescriptor = [bodyFontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        UIFont *boldBodyFont = [UIFont fontWithDescriptor:boldBodyFontDescriptor size:0];
        
        NSRange range = NSMakeRange(0, _backingStore.string.length);
        __block NSInteger i = 0;
        // TODO: Do we really need to enumerate all lines?
        [_backingStore.string enumerateSubstringsInRange:range options:NSStringEnumerationByParagraphs usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            NSString *trimmed = [substring stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (i == 0 && trimmed.length == 0) return; // Skip first empty lines, if any

            UIFont *font = i == 0 ? boldBodyFont : bodyFont;
            [_backingStore addAttribute:NSFontAttributeName value:font range:substringRange];
            i++;
        }];
        [self performReplacementsForRange:self.editedRange];
    }
    [super processEditing];
}

#pragma mark - Private

- (void)performReplacementsForRange:(NSRange)changedRange
{
    NSRange extendedRange = NSUnionRange(changedRange, [_backingStore.string lineRangeForRange:NSMakeRange(changedRange.location, 0)]);
    extendedRange = NSUnionRange(changedRange, [_backingStore.string lineRangeForRange:NSMakeRange(NSMaxRange(changedRange), 0)]);
    [self applyStylesToRange:extendedRange];
}

- (void)applyStylesToRange:(NSRange)searchRange
{
    NSRegularExpression* regex = [HPNote tagRegularExpression];
    UIColor *color = [UIApplication sharedApplication].keyWindow.tintColor;
    NSDictionary* attributes = @{ NSForegroundColorAttributeName : color };
    
    [self removeAttribute:NSForegroundColorAttributeName range:searchRange];
    
    [regex enumerateMatchesInString:_backingStore.string
                            options:0
                              range:searchRange
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
    {
        NSRange matchRange = [match rangeAtIndex:0];
        [self addAttributes:attributes range:matchRange];
    }];
}

@end
