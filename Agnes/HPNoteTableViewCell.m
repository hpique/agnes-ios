//
//  HPNoteTableViewCell.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteTableViewCell.h"
#import "HPNote.h"

static void *HPNoteTableViewCellContext = &HPNoteTableViewCellContext;

static UIFontDescriptor *_titleFontDescriptor;
static UIFontDescriptor *_archivedTitleFontDescriptor;
static UIFontDescriptor *_detailFontDescriptor;
static UIFontDescriptor *_archivedDetailFontDescriptor;

@implementation HPNoteTableViewCell

- (void)dealloc
{
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
    
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(cd_archived)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(cd_views)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(text)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(modifiedAt)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self displayNote];
}

- (UIFontDescriptor*)detailFontDescriptor
{
    if (!_detailFontDescriptor)
    {
        _detailFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleSubheadline];
        _archivedDetailFontDescriptor = [_detailFontDescriptor fontDescriptorWithSymbolicTraits:_detailFontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic];
    }
    return self.note.archived ? _archivedDetailFontDescriptor : _detailFontDescriptor;
}

- (UIFontDescriptor*)titleFontDescriptor
{
    if (!_titleFontDescriptor)
    {
        _titleFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleHeadline];
        _archivedTitleFontDescriptor = [_titleFontDescriptor fontDescriptorWithSymbolicTraits:_titleFontDescriptor.symbolicTraits | UIFontDescriptorTraitItalic];
    }
    return self.note.archived ? _archivedTitleFontDescriptor : _titleFontDescriptor;
}

#pragma mark - Private

- (void)displayNote
{
    self.titleLabel.font = [UIFont fontWithDescriptor:self.titleFontDescriptor size:0];
    self.bodyLabel.font =  [UIFont fontWithDescriptor:self.detailFontDescriptor size:0];
    
    NSDictionary *attributes = @{NSFontAttributeName: self.titleLabel.font};
    
    NSString *title = self.note.title;
    CGRect titleRect = [title boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) attributes:attributes context:nil];
    CGRect singleLineRect = [@"" boundingRectWithSize:CGSizeMake(CGRectGetWidth(self.bounds), CGFLOAT_MAX) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) attributes:attributes context:nil];
    NSInteger lines = round(titleRect.size.height / singleLineRect.size.height);
    NSInteger maximumBodyLines = self.titleLabel.numberOfLines - lines;
    self.bodyLabel.hidden = maximumBodyLines == 0;
    self.bodyLabel.numberOfLines = maximumBodyLines;
}

- (void)removeNoteObserver
{
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(cd_archived))];
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(cd_views))];
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(text))];
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(modifiedAt))];
}

@end
