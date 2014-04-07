//
//  HPNoteSearchTableViewCell.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteSearchTableViewCell.h"
#import "HPNote.h"
#import "HPNote+List.h"
#import "AGNPreferencesManager.h"
#import "HPFontManager.h"
#import "NSString+hp_utils.h"

static void *HPNoteSearchTableViewCellContext = &HPNoteSearchTableViewCellContext;

@implementation HPNoteSearchTableViewCell

#pragma mark - Public

+ (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width searchText:(NSString*)searchText
{
    HPFontManager *fonts = [HPFontManager sharedManager];

    UIFont *titleFont = [fonts fontForTitleOfNote:note];
    const CGFloat titleWidth = [self widthForTitleOfNote:note cellWidth:width];
    NSString *titleMatch = HPLineWithMatch(note.title, searchText);
    const CGFloat titleLineHeight = fonts.noteTitleLineHeight;
    NSString *title = titleMatch ? : note.title;
    NSUInteger titleLines = [title hp_linesWithFont:titleFont width:titleWidth lineHeight:titleLineHeight];
    titleLines = MIN(HPNoteTableViewCellLineCount, titleLines);

    NSString *bodyMatch = HPLineWithMatch(note.body, searchText);
    if (titleMatch == nil && bodyMatch != nil)
    { // Give more lines to the body
        titleLines = 1;
    }
    
    UIFont *bodyFont = [fonts fontForBodyOfNote:note];
    const CGFloat bodyLineHeight = fonts.noteBodyLineHeight;
    NSString *body = bodyMatch ? : note.body;
    NSUInteger bodyLines = body.length > 0 ? [body hp_linesWithFont:bodyFont width:titleWidth lineHeight:bodyLineHeight] : 0;
    const NSUInteger maximumBodyLines = HPNoteTableViewCellLineCount - titleLines;
    bodyLines = MAX(0, MIN(maximumBodyLines, bodyLines));
    
    CGFloat height = titleLines * titleLineHeight + bodyLines * bodyLineHeight + HPNoteTableViewCellMargin * 2;
    const BOOL hasThumbnail = note.hasThumbnail;
    return hasThumbnail ? MAX([self thumbnailViewWidth] + HPNoteTableViewCellMargin * 2, height) : height;
}

#pragma mark - Private

- (void)displayNote
{
    [super displayNote];
    const BOOL matchesTitle = [self setText:self.note.title inSearchLabel:self.titleLabel];
    const BOOL matchesBody = [self setText:self.note.body inSearchLabel:self.bodyLabel];
    if (!matchesTitle && matchesBody)
    { // Give more lines to the body
        self.titleLabel.numberOfLines = 1;
        self.bodyLabel.numberOfLines = HPNoteTableViewCellLineCount - self.titleLabel.numberOfLines;
    }
}

- (BOOL)setText:(NSString*)text inSearchLabel:(UILabel*)label
{
    NSString *match = HPLineWithMatch(text, self.searchText);
    if (match)
    {
        NSAttributedString *highlightedText = [self highlightMatchesInText:match];
        label.attributedText = highlightedText;
        return YES;
    }
    else
    {
        label.text = text;
        return NO;
    }
}

static NSString* HPLineWithMatch(NSString *text, NSString *search)
{
    NSRange searchRange = NSMakeRange(0, text.length);
    NSRange matchRange = [text rangeOfString:search options:NSCaseInsensitiveSearch range:searchRange];
    if (matchRange.location != NSNotFound)
    {
        NSRange matchLineRange = [text lineRangeForRange:matchRange];
        NSString *matchLine = [text substringWithRange:matchLineRange];
        return matchLine;
    }
    return nil;
}

- (NSAttributedString*)highlightMatchesInText:(NSString*)text
{
    AGNPreferencesManager *preferences = [AGNPreferencesManager sharedManager];
    UIColor *matchColor = preferences.tintColor;
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text];
    [text hp_enumerateOccurrencesOfString:self.searchText options:NSCaseInsensitiveSearch usingBlock:^(NSRange matchRange, BOOL *stop) {
        [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:matchColor range:matchRange];
    }];
    return mutableAttributedString;
}

@end
