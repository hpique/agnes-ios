//
//  HPNoteListTableViewCell.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteListTableViewCell.h"
#import "HPNote.h"
#import "TTTAttributedLabel.h"
#import "HPPreferencesManager.h"
#import "HPFontManager.h"

@interface HPNoteListTableViewCell()

@property (nonatomic, weak) TTTAttributedLabel *titleLabel;
@property (nonatomic, weak) TTTAttributedLabel *bodyLabel;

@end

@implementation HPNoteListTableViewCell

#pragma mark - HPNoteTableViewCell

- (void)applyPreferences
{
    [super applyPreferences];
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    NSDictionary *highlightedAttributes = @{ NSForegroundColorAttributeName : preferences.tintColor };
    self.titleLabel.truncationTokenStringAttributes = highlightedAttributes;
    self.bodyLabel.truncationTokenStringAttributes =  highlightedAttributes;
}

- (void)displayNote
{
    [super displayNote];
    NSString *title = self.note.title;
    if (title)
    {
        [self setHighlightedText:self.note.title inLabel:self.titleLabel];
    }
    else
    { // KVO notifies nil property changes after note is deleted
        self.titleLabel.text = nil;
    }
    NSString *bodyForTag = [self.note bodyForTagWithName:self.tagName];
    if (bodyForTag)
    {
        [self setHighlightedText:bodyForTag inLabel:self.bodyLabel];
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
        HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
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
        return mutableAttributedString;
    }];
}

@end
