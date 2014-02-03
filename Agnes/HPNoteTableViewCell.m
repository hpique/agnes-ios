//
//  HPNoteTableViewCell.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteTableViewCell.h"
#import "HPNote.h"
#import "HPNote+Thumbnail.h"
#import "HPFontManager.h"
#import "HPPreferencesManager.h"
#import "NSString+hp_utils.h"
#import "UIColor+hp_utils.h"

NSInteger const HPNoteTableViewCellLabelMaxLength = 150;
CGFloat const HPNoteTableViewCellMargin = 10;
CGFloat const HPNoteTableViewCellMarginLeft = 15;
CGFloat const HPNoteTableViewCellThumbnailMarginLeadgin = 8;
NSUInteger const HPNoteTableViewCellLineCount = 3;

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
    
    {
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(_thumbnailView, _titleLabel, _detailLabel);
        _titleDetailConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_titleLabel]-8-[_detailLabel]" options:kNilOptions metrics:nil views:viewsDictionary];
        _thumbnailDetailConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_detailLabel]-8-[_thumbnailView]" options:kNilOptions metrics:nil views:viewsDictionary];
        _thumbnailTitleConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_titleLabel]-8-[_thumbnailView]" options:kNilOptions metrics:nil views:viewsDictionary];
        _bodyLabelAlignRightWithTitleLabelConstraint = [NSLayoutConstraint constraintWithItem:_bodyLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_titleLabel attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        
        self.thumbnailViewWidthConstraint.constant = [HPNoteTableViewCell thumbnailViewWidth];
        self.thumbnailViewHeightConstraint.constant = self.thumbnailViewWidthConstraint.constant;
        
        [self invalidateConstraints];
    }

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
    const BOOL hasThumbnail = self.note.hasThumbnail;
    if (hasThumbnail)
    {
        if (self.hasDetail)
        {
            [self.contentView addConstraints:_titleDetailConstraints];
            [self.contentView addConstraint:self.bodyLabelRightConstraint];
            [self.contentView addConstraints:_thumbnailDetailConstraints];
        }
        else
        {
            [self.contentView addConstraint:_bodyLabelAlignRightWithTitleLabelConstraint];
            [self.contentView addConstraints:_thumbnailTitleConstraints];
        }
    }
    else
    {
        if (self.hasDetail)
        {
            [self.contentView addConstraint:self.detailLabelTrailingSpaceConstraint];
            [self.contentView addConstraints:_titleDetailConstraints];
            [self.contentView addConstraint:self.bodyLabelRightConstraint];
        }
        else
        {
            [self.contentView addConstraint:self.titleLabelTrailingSpaceConstraint];
            [self.contentView addConstraint:_bodyLabelAlignRightWithTitleLabelConstraint];
        }
    }
    [super updateConstraints];
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
    [self invalidateConstraints];
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

+ (CGFloat)estimatedHeightForNote:(HPNote*)note
{
    CGFloat estimatedHeight = HPNoteTableViewCellMargin * 2;
    if (note.hasThumbnail)
    {
        estimatedHeight += [self thumbnailViewWidth];
    }
    else
    {
        HPFontManager *manager = [HPFontManager sharedManager];
        estimatedHeight += manager.noteTitleLineHeight + manager.noteBodyLineHeight;
    }
    return estimatedHeight;
}

+ (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width tagName:(NSString*)tagName
{
    HPFontManager *fonts = [HPFontManager sharedManager];
    
    UIFont *titleFont = [fonts fontForTitleOfNote:note];
    const CGFloat titleWidth = [self widthForTitleOfNote:note cellWidth:width];
    const CGFloat titleLineHeight = fonts.noteTitleLineHeight;
    NSUInteger titleLines = [note.title hp_linesWithFont:titleFont width:titleWidth lineHeight:titleLineHeight];

    UIFont *bodyFont = [fonts fontForBodyOfNote:note];
    const CGFloat bodyLineHeight = fonts.noteBodyLineHeight;
    NSString *body = [note bodyForTagWithName:tagName];
    NSUInteger bodyLines = body.length > 0 ? [body hp_linesWithFont:bodyFont width:titleWidth lineHeight:bodyLineHeight] : 0;
    const NSUInteger maximumBodyLines = HPNoteTableViewCellLineCount - titleLines;
    bodyLines = MAX(0, MIN(maximumBodyLines, bodyLines));
    
    CGFloat height = titleLines * titleLineHeight + bodyLines * bodyLineHeight + HPNoteTableViewCellMargin * 2;
    
    const BOOL hasThumbnail = note.hasThumbnail;
    return hasThumbnail ? MAX([self thumbnailViewWidth] + HPNoteTableViewCellMargin * 2, height) : height;
}

+ (CGFloat)thumbnailViewWidth
{
    return [HPFontManager sharedManager].noteTitleLineHeight * HPNoteTableViewCellLineCount;
}

+ (CGFloat)widthForTitleOfNote:(HPNote*)note cellWidth:(CGFloat)cellWidth
{
    CGFloat width = cellWidth - HPNoteTableViewCellMarginLeft * 2;
    if (note.hasThumbnail)
    {
        width -= HPNoteTableViewCellThumbnailMarginLeadgin + [self thumbnailViewWidth];
    }
    return width;
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
    HPFontManager *fonts = [HPFontManager sharedManager];
    
    self.titleLabel.font = [fonts fontForTitleOfNote:self.note];
    self.bodyLabel.font =  [fonts fontForBodyOfNote:self.note];
    
    NSString *title = self.note.title;

    const CGFloat titleWidth = [HPNoteTableViewCell widthForTitleOfNote:self.note cellWidth:self.bounds.size.width];
    
    self.titleLabel.preferredMaxLayoutWidth = titleWidth; // See: http://johnszumski.com/blog/auto-layout-for-table-view-cells-with-dynamic-heights
    self.bodyLabel.preferredMaxLayoutWidth = titleWidth;
    
    const CGFloat lineHeight = fonts.noteTitleLineHeight;
    NSInteger titleLines = [title hp_linesWithFont:self.titleLabel.font width:titleWidth lineHeight:lineHeight];
    self.titleLabel.numberOfLines = MIN(HPNoteTableViewCellLineCount, titleLines);
    
    NSInteger maximumBodyLines = HPNoteTableViewCellLineCount - self.titleLabel.numberOfLines;
    self.bodyLabel.hidden = maximumBodyLines == 0;
    self.bodyLabel.numberOfLines = maximumBodyLines;
    
    const BOOL hasThumbnail = self.note.hasThumbnail;
    if (hasThumbnail)
    {
        self.thumbnailView.hidden = NO;
        self.thumbnailView.image = self.note.thumbnail;
    }
    else
    {
        self.thumbnailView.hidden = YES;
        self.thumbnailView.image = nil;
    }

    [self displayDetail];

    [self invalidateConstraints];
    [self setNeedsUpdateConstraints];
}

- (BOOL)hasDetail
{
    return self.sortMode == HPTagSortModeModifiedAt;
}

- (void)invalidateConstraints
{
    [self.contentView removeConstraint:self.detailLabelTrailingSpaceConstraint];
    [self.contentView removeConstraint:self.titleLabelTrailingSpaceConstraint];
    [self.contentView removeConstraints:_titleDetailConstraints];
    [self.contentView removeConstraints:_thumbnailTitleConstraints];
    [self.contentView removeConstraints:_thumbnailDetailConstraints];
    [self.contentView removeConstraint:_bodyLabelAlignRightWithTitleLabelConstraint];
    [self.contentView removeConstraint:self.bodyLabelRightConstraint];
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
