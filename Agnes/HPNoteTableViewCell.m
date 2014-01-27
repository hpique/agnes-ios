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
#import "NSString+hp_layout.h"

NSInteger const HPNotTableViewCellLabelMaxLength = 150;

static void *HPNoteTableViewCellContext = &HPNoteTableViewCellContext;

@implementation HPNoteTableViewCell {
    BOOL _removedObserver;
}

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

#pragma mark - UITableViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self removeNoteObserver];
    self.tagName = nil;
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
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(isDeleted)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    _removedObserver = NO;
    [self displayNote];
}

+ (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width tagName:(NSString*)tagName
{
    // TODO: Consider display criteria width
    UIFont *titleFont = [[HPFontManager sharedManager] fontForTitleOfNote:note];
    CGFloat titleLineHeight;
    NSInteger titleLines = [note.title hp_linesWithFont:titleFont width:width lineHeight:&titleLineHeight];
    UIFont *bodyFont = [[HPFontManager sharedManager] fontForBodyOfNote:note];
    CGFloat bodyLineHeight = 0;
    NSString *body = [note bodyForTagWithName:tagName];
    NSInteger bodyLines = body.length > 0 ? [body hp_linesWithFont:bodyFont width:width lineHeight:&bodyLineHeight] : 0;
    NSInteger maximumBodyLines = 3 - titleLines;
    bodyLines = MAX(0, MIN(maximumBodyLines, bodyLines));
    return titleLines * titleLineHeight + bodyLines * bodyLineHeight + 10 * 2;
}

#pragma mark - Private

- (void)displayNote
{
    self.titleLabel.font = [[HPFontManager sharedManager] fontForTitleOfNote:self.note];
    self.bodyLabel.font =  [[HPFontManager sharedManager] fontForBodyOfNote:self.note];
    
    NSString *title = self.note.title;
    CGFloat lineHeight;
    NSInteger lines = [title hp_linesWithFont:self.titleLabel.font width:CGRectGetWidth(self.bounds) lineHeight:&lineHeight];
    NSInteger maximumBodyLines = self.titleLabel.numberOfLines - lines;
    self.bodyLabel.hidden = maximumBodyLines == 0;
    self.bodyLabel.numberOfLines = maximumBodyLines;
}

- (void)removeNoteObserver
{
    if (_removedObserver) return;
    
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(cd_archived))];
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(cd_views))];
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(text))];
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(modifiedAt))];
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(isDeleted))];
    _removedObserver = YES;
}

@end
