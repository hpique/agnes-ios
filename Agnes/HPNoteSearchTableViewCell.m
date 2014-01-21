//
//  HPNoteSearchTableViewCell.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteSearchTableViewCell.h"
#import "HPNote.h"

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
    [self setText:self.note.title inSearchResultlabel:self.titleLabel fontDescriptor:self.titleFontDescriptor];
    [self setText:self.note.body inSearchResultlabel:self.bodyLabel fontDescriptor:self.detailFontDescriptor];
}

- (void)setText:(NSString*)text inSearchResultlabel:(UILabel*)label fontDescriptor:(UIFontDescriptor*)fontDescriptor
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange searchRange = NSMakeRange(0, text.length);
    NSRange foundRange;
    
    UIFontDescriptor *boldFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:fontDescriptor.symbolicTraits | UIFontDescriptorTraitBold];
    UIFont *boldFont = [UIFont fontWithDescriptor:boldFontDescriptor size:0];
    
    while (searchRange.location < text.length)
    {
        searchRange.length = text.length - searchRange.location;
        foundRange = [text rangeOfString:self.searchText options:NSCaseInsensitiveSearch range:searchRange];
        if (foundRange.location != NSNotFound)
        {
            [attributedText addAttribute:NSFontAttributeName value:boldFont range:foundRange];
            searchRange.location = foundRange.location+foundRange.length;
        } else break;
    }
    label.attributedText = attributedText;
}

@end
