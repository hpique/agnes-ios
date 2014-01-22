//
//  HPNoteTableViewCell.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteTableViewCell.h"
#import "HPNote.h"
#import "HPFontManager.h"

static void *HPNoteTableViewCellContext = &HPNoteTableViewCellContext;

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

#pragma mark - Private

- (void)displayNote
{
    self.titleLabel.font = [[HPFontManager sharedManager] fontForTitleOfNote:self.note];
    self.bodyLabel.font =  [[HPFontManager sharedManager] fontForBodyOfNote:self.note];
    
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
