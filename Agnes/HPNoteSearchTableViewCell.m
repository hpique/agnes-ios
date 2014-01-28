//
//  HPNoteSearchTableViewCell.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteSearchTableViewCell.h"
#import "HPNote.h"
#import "HPPreferencesManager.h"
#import "HPFontManager.h"
#import "NSString+hp_utils.h"

static void *HPNoteSearchTableViewCellContext = &HPNoteSearchTableViewCellContext;

@implementation HPNoteSearchTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

#pragma mark - Public

+ (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width searchText:(NSString*)searchText
{
    UIFont *titleFont = [[HPFontManager sharedManager] fontForTitleOfNote:note];
    NSString *titleMatch = HPLineWithMatch(note.title, searchText);
    CGFloat titleLineHeight = 0;
    NSString *title = titleMatch ? : note.title;
    NSInteger titleLines = [title hp_linesWithFont:titleFont width:width lineHeight:&titleLineHeight];
    if (!titleMatch)
    {
        titleLines = 1;
    }
    UIFont *bodyFont = [[HPFontManager sharedManager] fontForBodyOfNote:note];
    CGFloat bodyLineHeight = 0;
    NSString *body = HPLineWithMatch(note.body, searchText) ? : note.body;
    NSInteger bodyLines = body.length > 0 ? [body hp_linesWithFont:bodyFont width:width lineHeight:&bodyLineHeight] : 0;
    NSInteger maximumBodyLines = 3 - titleLines;
    bodyLines = MAX(0, MIN(maximumBodyLines, bodyLines));
    return titleLines * titleLineHeight + bodyLines * bodyLineHeight + 10 * 2;
}

#pragma mark - Private

- (void)displayNote
{
    [super displayNote];
    [self setText:self.note.title inSearchLabel:self.titleLabel];
    [self setText:self.note.body inSearchLabel:self.bodyLabel];
}

- (void)setText:(NSString*)text inSearchLabel:(UILabel*)label
{
    NSString *match = HPLineWithMatch(text, self.searchText);
    if (match)
    {
        NSAttributedString *highlightedText = [self highlightMatchesInText:match];
        label.attributedText = highlightedText;
    }
    else
    {
        label.text = text;
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
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    UIColor *matchColor = preferences.tintColor;
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:text];
    [text hp_enumerateOccurrencesOfString:self.searchText options:NSCaseInsensitiveSearch usingBlock:^(NSRange matchRange, BOOL *stop) {
        [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:matchColor range:matchRange];
    }];
    return mutableAttributedString;
}

@end
