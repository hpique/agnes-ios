//
//  HPNoteTableViewCell.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteTableViewCell.h"
#import "HPNote.h"
#import "HPAttachment.h"
#import "HPFontManager.h"
#import "HPPreferencesManager.h"
#import "NSString+hp_utils.h"
#import "UIColor+hp_utils.h"

NSInteger const HPNoteTableViewCellLabelMaxLength = 150;
CGFloat const HPNoteTableViewCellMargin = 10;
CGFloat const HPNoteTableViewCellImageHeight = 60;

static void *HPNoteTableViewCellContext = &HPNoteTableViewCellContext;

@interface HPNoteTableViewCell()

@property (nonatomic, readonly) BOOL hasDetail;

@end

@implementation HPNoteTableViewCell {
    BOOL _removedObserver;
    NSArray *_titleDetailConstraints;
    NSArray *_thumbnailDetailConstraints;
    NSArray *_thumbnailTitleConstraints;
    NSLayoutConstraint *_bodyLabelAlignRightWithTitleLabelConstraint;
    NSTimer *_modifiedAtSortModeTimer;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self)
    {
        [self initHelper];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self initHelper];
}

- (void)initHelper
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:HPPreferencesManagerDidChangePreferencesNotification object:[HPPreferencesManager sharedManager]];
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_thumbnailView, _titleLabel, _detailLabel);
    _titleDetailConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_titleLabel]-8-[_detailLabel]" options:kNilOptions metrics:nil views:viewsDictionary];
    _thumbnailDetailConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_detailLabel]-8-[_thumbnailView]" options:kNilOptions metrics:nil views:viewsDictionary];
    _thumbnailTitleConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_titleLabel]-8-[_thumbnailView]" options:kNilOptions metrics:nil views:viewsDictionary];
    _bodyLabelAlignRightWithTitleLabelConstraint = [NSLayoutConstraint constraintWithItem:_bodyLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_titleLabel attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    
    self.thumbnailView.layer.borderWidth = 1;
    [self applyPreferences];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPPreferencesManagerDidChangePreferencesNotification object:[HPPreferencesManager sharedManager]];
    [self removeNoteObserver];
    [_modifiedAtSortModeTimer invalidate];
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

#pragma mark - UIView

- (void)updateConstraints
{
    [super updateConstraints];
    HPAttachment *attachment = [self.note.attachments anyObject];
    if (attachment)
    {
        [self.contentView removeConstraint:self.detailLabelTrailingSpaceConstraint];
        [self.contentView removeConstraint:self.titleLabelTrailingSpaceConstraint];
        if (self.hasDetail)
        {
            [self.contentView removeConstraints:_thumbnailTitleConstraints];
            [self.contentView removeConstraint:_bodyLabelAlignRightWithTitleLabelConstraint];
            [self.contentView addConstraints:_titleDetailConstraints];
            [self.contentView addConstraint:self.bodyLabelRightConstraint];
            [self.contentView addConstraints:_thumbnailDetailConstraints];
        }
        else
        {
            [self.contentView removeConstraints:_titleDetailConstraints];
            [self.contentView removeConstraints:_thumbnailDetailConstraints];
            [self.contentView removeConstraint:self.bodyLabelRightConstraint];
            [self.contentView addConstraint:_bodyLabelAlignRightWithTitleLabelConstraint];
            [self.contentView addConstraints:_thumbnailTitleConstraints];
        }
    }
    else
    {
        [self.contentView removeConstraints:_thumbnailDetailConstraints];
        [self.contentView removeConstraints:_thumbnailTitleConstraints];
        if (self.hasDetail)
        {
            [self.contentView removeConstraint:self.titleLabelTrailingSpaceConstraint];
            [self.contentView removeConstraint:_bodyLabelAlignRightWithTitleLabelConstraint];
            [self.contentView addConstraint:self.detailLabelTrailingSpaceConstraint];
            [self.contentView addConstraints:_titleDetailConstraints];
            [self.contentView addConstraint:self.bodyLabelRightConstraint];
        }
        else
        {
            [self.contentView removeConstraints:_titleDetailConstraints];
            [self.contentView removeConstraint:self.detailLabelTrailingSpaceConstraint];
            [self.contentView removeConstraint:self.bodyLabelRightConstraint];
            [self.contentView addConstraint:self.titleLabelTrailingSpaceConstraint];
            [self.contentView addConstraint:_bodyLabelAlignRightWithTitleLabelConstraint];
        }

    }
}

#pragma mark - UITableViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self removeNoteObserver];
    self.thumbnailView.image = nil;
    self.tagName = nil;
    self.thumbnailView.hidden = YES;
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

- (void)setSortMode:(HPTagSortMode)sortMode animated:(BOOL)animated
{
    [_modifiedAtSortModeTimer invalidate];
    _sortMode = sortMode;
    [self displayDetail];
    if (_sortMode == HPTagSortModeModifiedAt)
    {
        static NSTimeInterval updateDetailDelay = 30;
        _modifiedAtSortModeTimer = [NSTimer scheduledTimerWithTimeInterval:updateDetailDelay target:self selector:@selector(displayDetail) userInfo:nil repeats:YES];
    }
    [self setNeedsUpdateConstraints];
    if (animated)
    {
        [UIView animateWithDuration:0.2 animations:^{
            [self layoutIfNeeded]; // TODO: This doesn't animate the layout change. Why?
        }];
    }
    else
    {
        [self setNeedsLayout];
    }
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
    CGFloat height = titleLines * titleLineHeight + bodyLines * bodyLineHeight + HPNoteTableViewCellMargin * 2;
    return note.attachments.count > 0 ? MAX(HPNoteTableViewCellImageHeight + HPNoteTableViewCellMargin * 2, height) : height;
}

#pragma mark - Private

- (void)applyPreferences
{
    UIColor *borderColor = [HPPreferencesManager sharedManager].tintColor;
    borderColor = [borderColor hp_lighterColor];
    self.thumbnailView.layer.borderColor = borderColor.CGColor;
}

- (void)displayDetail
{
    self.detailLabel.hidden = !self.hasDetail;
    self.detailLabel.font = [[HPFontManager sharedManager] fontForDetail];
    NSString *detailText = @"";
    switch (self.sortMode)
    {
        case HPTagSortModeModifiedAt:
            detailText = self.note.modifiedAtDescription;
            break;
        default:
            break;
    }
    self.detailLabel.text = detailText;
}

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
    
    HPAttachment *attachment = [self.note.attachments anyObject];
    if (attachment)
    {
        self.thumbnailView.hidden = NO;
        self.thumbnailView.image = attachment.thumbnail;
    }
    else
    {
        self.thumbnailView.hidden = YES;
        self.thumbnailView.image = nil;
    }
    [self displayDetail];
    [self setNeedsUpdateConstraints];
}

- (BOOL)hasDetail
{
    return self.sortMode == HPTagSortModeModifiedAt;
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

#pragma mark - Actions

- (void)didChangePreferences:(NSNotification*)notification
{
    if (!self.note) return;
    [self applyPreferences];
    [self displayNote];
}


@end
