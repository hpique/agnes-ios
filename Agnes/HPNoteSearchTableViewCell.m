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
#import "TTTAttributedLabel.h"

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

#pragma mark - Private

- (void)displayNote
{
    [super displayNote];
    [self setText:self.note.title inSearchResultlabel:self.titleLabel];
    [self setText:self.note.body inSearchResultlabel:self.bodyLabel];
}

- (void)setText:(NSString*)text inSearchResultlabel:(UILabel*)label
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange searchRange = NSMakeRange(0, text.length);
    NSRange foundRange;
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    while (searchRange.location < text.length)
    {
        searchRange.length = text.length - searchRange.location;
        foundRange = [text rangeOfString:self.searchText options:NSCaseInsensitiveSearch range:searchRange];
        if (foundRange.location != NSNotFound)
        {
            [attributedText addAttribute:NSForegroundColorAttributeName value:preferences.tintColor range:foundRange];
            searchRange.location = foundRange.location+foundRange.length;
        } else break;
    }
    label.attributedText = attributedText;
}

@end
