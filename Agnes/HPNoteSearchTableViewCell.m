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

- (void)dealloc
{
    [self removeNoteObserver];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == HPNoteSearchTableViewCellContext)
    {
        [self displayNote];
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Public

- (void)setNote:(HPNote *)note
{
    [self removeNoteObserver];
    _note = note;
    
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(text)) options:NSKeyValueObservingOptionNew context:HPNoteSearchTableViewCellContext];
    [self displayNote];
}

#pragma mark - Private

- (void)displayNote
{
    [self setText:self.note.title inSearchResultlabel:self.textLabel];
    [self setText:self.note.body inSearchResultlabel:self.detailTextLabel];
}

- (void)setText:(NSString*)text inSearchResultlabel:(UILabel*)label
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    NSRange searchRange = NSMakeRange(0, text.length);
    NSRange foundRange;
    
    UIFontDescriptor *fontDescriptor = label.font.fontDescriptor;
    UIFontDescriptor *boldFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
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

- (void)removeNoteObserver
{
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(text))];
}

@end
