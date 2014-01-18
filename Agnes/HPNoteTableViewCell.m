//
//  HPNoteTableViewCell.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteTableViewCell.h"
#import "HPNote.h"

static void *HPNoteTableViewCellContext = &HPNoteTableViewCellContext;

static UIFont *_titleFont;
static UIFont *_archivedTitleFont;

@implementation HPNoteTableViewCell {
    NSTimer *_modifiedAtDisplayCriteriaTimer;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)dealloc
{
    [_modifiedAtDisplayCriteriaTimer invalidate];
    [self removeNoteObserver];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == HPNoteTableViewCellContext)
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
    
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(archived)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(text)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(modifiedAt)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self displayNote];
}

- (void)setDisplayCriteria:(HPNoteDisplayCriteria)displayCriteria
{
    [_modifiedAtDisplayCriteriaTimer invalidate];
    _displayCriteria = displayCriteria;
    [self displayDetail];
    if (_displayCriteria == HPNoteDisplayCriteriaModifiedAt)
    {
        static NSTimeInterval updateDetailDelay = 30;
        _modifiedAtDisplayCriteriaTimer = [NSTimer scheduledTimerWithTimeInterval:updateDetailDelay target:self selector:@selector(displayDetail) userInfo:nil repeats:YES];
    }
}

#pragma mark - Private

- (void)displayNote
{
    if (!_titleFont)
    {
        UIFontDescriptor *fontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
        UIFontDescriptor *italicFontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
        _titleFont = [UIFont fontWithDescriptor:fontDescriptor size:0];
        _archivedTitleFont = [UIFont fontWithDescriptor:italicFontDescriptor size:0];
    }
    
    self.textLabel.font = self.note.archived ? _archivedTitleFont : _titleFont;
    self.textLabel.text = self.note.title;
    [self displayDetail];
}

- (void)displayDetail
{
    NSString *detailText = @"";
    switch (self.displayCriteria)
    {
        case HPNoteDisplayCriteriaModifiedAt:
            detailText = self.note.modifiedAtDescription;
            break;
        default:
            break;
    }
    self.detailTextLabel.text = detailText;
}

- (void)removeNoteObserver
{
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(archived))];
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(text))];
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(modifiedAt))];
}

@end
