//
//  HPNoteListTableViewCell.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteListTableViewCell.h"
#import "HPNote.h"
#import "HPTag.h"
#import "HPNote+List.h"
#import "TTTAttributedLabel.h"
#import "AGNPreferencesManager.h"
#import "HPFontManager.h"

@interface HPNoteListTableViewCell()

@property (nonatomic, weak) TTTAttributedLabel *titleLabel;
@property (nonatomic, weak) TTTAttributedLabel *bodyLabel;

@end

@implementation HPNoteListTableViewCell

#pragma mark HPNoteTableViewCell

- (NSString*)bodyForTransition
{
    NSString *body = [super bodyForTransition];
    if (body.length > 0)
    {
        NSRange ellipsisRange = [body rangeOfString:@"…" options:kNilOptions range:NSMakeRange(body.length - 1, 1)];
        if (ellipsisRange.location != NSNotFound)
        {
            body = [body stringByReplacingCharactersInRange:ellipsisRange withString:@""];
        }
    }
    return body;
}

#pragma mark HPNoteTableViewCell(Subclassing)

- (void)applyPreferences
{
    [super applyPreferences];
    AGNPreferencesManager *preferences = [AGNPreferencesManager sharedManager];
    HPFontManager *fonts = [HPFontManager sharedManager];
    self.titleLabel.truncationTokenStringAttributes = @{ NSFontAttributeName : fonts.fontForNoteTitle, NSForegroundColorAttributeName : preferences.tintColor };
    self.bodyLabel.truncationTokenStringAttributes =  @{ NSFontAttributeName : fonts.fontForNoteBody, NSForegroundColorAttributeName : preferences.tintColor };
}

- (void)displayNote
{
    [super displayNote];
    HPNote *note = self.note;
    NSString *title = note.title;
    if (title)
    {
        [self setHighlightedText:note.title inLabel:self.titleLabel];
    }
    else
    { // KVO notifies nil property changes after note is deleted
        self.titleLabel.text = nil;
    }
    NSString *summaryForTag = [note summaryForTag:self.agnesTag];
    if (summaryForTag)
    {
        if (!self.isTruncatedSummary && summaryForTag.length > 0)
        {
            NSString *body = note.body;
            NSRange range = [body rangeOfString:summaryForTag];
            if (NSMaxRange(range) < body.length)
            {
                NSCharacterSet *terminatorSet = [NSCharacterSet characterSetWithCharactersInString:@".…"];
                NSRange range = [summaryForTag rangeOfCharacterFromSet:terminatorSet options:kNilOptions range:NSMakeRange(summaryForTag.length - 1, 1)];
                NSMutableString *mutableSummary = summaryForTag.mutableCopy;
                if (range.location != NSNotFound)
                {
                    [mutableSummary deleteCharactersInRange:range];
                }
                [mutableSummary appendString:@"…"];
                summaryForTag = mutableSummary;
            }
        }
        [self setHighlightedText:summaryForTag inLabel:self.bodyLabel];
    }
    else
    {
        self.bodyLabel.text = nil;
    }
}

#pragma mark - Private

- (void)setHighlightedText:(NSString*)text inLabel:(TTTAttributedLabel*)label
{
    [label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        AGNPreferencesManager *preferences = [AGNPreferencesManager sharedManager];
        NSRegularExpression* regex = [HPNote tagRegularExpression];
        NSDictionary* attributes = @{ NSForegroundColorAttributeName : preferences.tintColor };
        
        NSInteger maxLength = MIN(HPNoteTableViewCellLabelMaxLength, text.length);
        [regex enumerateMatchesInString:text
                                options:0
                                  range:NSMakeRange(0, maxLength)
                             usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
         {
             NSRange matchRange = [match rangeAtIndex:0];
             [mutableAttributedString addAttributes:attributes range:matchRange];
         }];
        if (text.length > 0)
        {
            NSRange ellipsisRange = [text rangeOfString:@"…" options:kNilOptions range:NSMakeRange(text.length - 1, 1)];
            if (ellipsisRange.location != NSNotFound)
            {
                [mutableAttributedString addAttributes:attributes range:ellipsisRange];
            }
        }
        return mutableAttributedString;
    }];
}

@end
