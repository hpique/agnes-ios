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
#import "HPAgnesUIMetrics.h"

NSInteger const HPNoteTableViewCellLabelMaxLength = 150;
CGFloat const HPNoteTableViewCellMargin = 10;
CGFloat const HPNoteTableViewCellMarginLeft = 15;
CGFloat const HPNoteTableViewCellThumbnailMarginLeadgin = 8;
NSUInteger const HPNoteTableViewCellLineCount = 3;

NSString *const HPNoteHeightCacheDefault = @"d";

@interface HPNoteHeightCache : NSObject

- (CGFloat)heightForNote:(HPNote*)note kind:(NSString*)kind;

- (void)setHeight:(CGFloat)height forNote:(HPNote*)note kind:(NSString*)kind;

@end

@implementation HPNoteHeightCache {
    NSCache *_cache;
}

- (id)init
{
    if (self = [super init])
    {
        _cache = [[NSCache alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fontsDidChangeNotification:) name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    }
    return self;
}

- (CGFloat)heightForNote:(HPNote*)note kind:(NSString*)kind
{
    NSDictionary *dictionary = [_cache objectForKey:note.uuid];
    NSNumber *value = [dictionary objectForKey:kind];
    return value ? [value floatValue] : 0;
}

- (void)setHeight:(CGFloat)height forNote:(HPNote*)note kind:(NSString*)kind
{
    NSDictionary *dictionary = [_cache objectForKey:note.uuid];
    if (!dictionary) dictionary = [NSDictionary dictionary];
    NSMutableDictionary *updatedDictionary = dictionary.mutableCopy;
    [updatedDictionary setObject:@(height) forKey:kind];
    [_cache setObject:updatedDictionary forKey:note.uuid];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
}

+ (HPNoteHeightCache*)sharedCache
{
    static HPNoteHeightCache *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPNoteHeightCache alloc] init];
    });
    return instance;
}

- (void)notesDidChangeNotification:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSSet *deleted = [userInfo objectForKey:NSDeletedObjectsKey];
    NSSet *updated = [userInfo objectForKey:NSUpdatedObjectsKey];
    NSSet *invalidated = [deleted setByAddingObjectsFromSet:updated];
    for (HPNote *note in invalidated)
    {
        [_cache removeObjectForKey:note.uuid];
    }
}

- (void)fontsDidChangeNotification:(NSNotification*)notification
{
    [_cache removeAllObjects];
}

@end


static void *HPNoteTableViewCellContext = &HPNoteTableViewCellContext;

typedef NS_ENUM(NSInteger, HPNoteTableViewCellLayoutMode)
{
    HPNoteTableViewCellLayoutModeDefault,
    HPNoteTableViewCellLayoutModeDetail,
    HPNoteTableViewCellLayoutModeThumbnail,
    HPNoteTableViewCellLayoutModeDetailThumbnail,
};

@interface HPNoteTableViewCell()

@property (nonatomic, readonly) BOOL hasDetail;

@end

@implementation HPNoteTableViewCell {
    BOOL _removedObserver;
    NSArray *_titleDetailConstraints;
    NSArray *_thumbnailDetailConstraints;
    NSArray *_thumbnailTitleConstraints;
    NSLayoutConstraint *_bodyLabelAlignRightToDetailConstraint;
    NSTimer *_modifiedAtSortModeTimer;
    HPNoteTableViewCellLayoutMode _layoutMode;
}

@synthesize tagName = _tagName;
@synthesize detailMode = _detailMode;

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
        _bodyLabelAlignRightToDetailConstraint = [NSLayoutConstraint constraintWithItem:_bodyLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_detailLabel attribute:NSLayoutAttributeRight multiplier:1 constant:0];
        
        self.thumbnailViewWidthConstraint.constant = [HPNoteTableViewCell thumbnailViewWidth];
        self.thumbnailViewHeightConstraint.constant = self.thumbnailViewWidthConstraint.constant;
    }
    
    _layoutMode = HPNoteTableViewCellLayoutModeDefault;
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

- (void)layoutSubviews
{
    [self setMargins];
    [super layoutSubviews];
}

- (void)updateConstraints
{
    [self setMargins];

    switch (_layoutMode) {
        case HPNoteTableViewCellLayoutModeDefault:
            [self.contentView addConstraint:self.titleLabelTrailingSpaceConstraint];
            [self.contentView addConstraint:self.bodyLabelAlignRightToTitleConstraint];
            break;
        case HPNoteTableViewCellLayoutModeDetail:
            [self.contentView addConstraint:self.detailLabelTrailingSpaceConstraint];
            [self.contentView addConstraints:_titleDetailConstraints];
            [self.contentView addConstraint:_bodyLabelAlignRightToDetailConstraint];
            break;
        case HPNoteTableViewCellLayoutModeThumbnail:
            [self.contentView addConstraint:self.bodyLabelAlignRightToTitleConstraint];
            [self.contentView addConstraints:_thumbnailTitleConstraints];
            break;
        case HPNoteTableViewCellLayoutModeDetailThumbnail:
            [self.contentView addConstraints:_titleDetailConstraints];
            [self.contentView addConstraint:_bodyLabelAlignRightToDetailConstraint];
            [self.contentView addConstraints:_thumbnailDetailConstraints];
        default:
            break;
    }
    [super updateConstraints];
}

#pragma mark - UITableViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self removeNoteObserver];
    self.thumbnailView.image = nil;
    _tagName = nil;
    self.thumbnailView.hidden = YES;
}

#pragma mark - Public

- (void)setNote:(HPNote *)note ofTagNamed:(NSString*)tagName detailMode:(HPTagSortMode)detailMode
{
    [self removeNoteObserver];
    _note = note;
    _tagName = [tagName copy];
    self.detailMode = detailMode;
    
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(cd_archived)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(cd_views)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(text)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(modifiedAt)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(isDeleted)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    _removedObserver = NO;
    
    [self displayNote];
}

- (void)setDetailMode:(HPTagSortMode)detailMode animated:(BOOL)animated
{
    self.detailMode = detailMode;
    [self invalidateConstraintsIfNeeded];
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

+ (CGFloat)estimatedHeightForNote:(HPNote*)note inTagNamed:(NSString *)tagName
{
    CGFloat estimatedHeight = [[HPNoteHeightCache sharedCache] heightForNote:note kind:tagName ? : HPNoteHeightCacheDefault];
    if (estimatedHeight > 0) return estimatedHeight;
    if (tagName)
    { // Try default height
        estimatedHeight = [[HPNoteHeightCache sharedCache] heightForNote:note kind:HPNoteHeightCacheDefault];
    }
    if (estimatedHeight > 0) return estimatedHeight;
    
    estimatedHeight = HPNoteTableViewCellMargin * 2;
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
    CGFloat cachedHeight = [[HPNoteHeightCache sharedCache] heightForNote:note kind:tagName ? : HPNoteHeightCacheDefault];
    if (cachedHeight > 0) return cachedHeight;

    HPFontManager *fonts = [HPFontManager sharedManager];
    
    UIFont *titleFont = [fonts fontForTitleOfNote:note];
    const CGFloat titleWidth = [self widthForTitleOfNote:note cellWidth:width];
    const CGFloat titleLineHeight = fonts.noteTitleLineHeight;
    NSUInteger titleLines = [note.title hp_linesWithFont:titleFont width:titleWidth lineHeight:titleLineHeight];

    UIFont *bodyFont = [fonts fontForBodyOfNote:note];
    const CGFloat bodyLineHeight = fonts.noteBodyLineHeight;
    NSString *summary = [note summaryForTagNamed:tagName];
    NSUInteger bodyLines = summary.length > 0 ? [summary hp_linesWithFont:bodyFont width:titleWidth lineHeight:bodyLineHeight] : 0;
    const NSUInteger maximumBodyLines = HPNoteTableViewCellLineCount - titleLines;
    bodyLines = MAX(0, MIN(maximumBodyLines, bodyLines));
    
    CGFloat height = titleLines * titleLineHeight + bodyLines * bodyLineHeight + HPNoteTableViewCellMargin * 2;
    
    const BOOL hasThumbnail = note.hasThumbnail;
    height = hasThumbnail ? MAX([self thumbnailViewWidth] + HPNoteTableViewCellMargin * 2, height) : height;
    [[HPNoteHeightCache sharedCache] setHeight:height forNote:note kind:tagName ? : HPNoteHeightCacheDefault];
    return height;
}

+ (CGFloat)thumbnailViewWidth
{
    return [HPFontManager sharedManager].noteTitleLineHeight * HPNoteTableViewCellLineCount;
}

+ (CGFloat)widthForTitleOfNote:(HPNote*)note cellWidth:(CGFloat)cellWidth
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat width = cellWidth - [HPAgnesUIMetrics sideMarginForInterfaceOrientation:orientation] * 2;
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

- (HPNoteTableViewCellLayoutMode)calculateLayoutMode
{
    if (self.note.hasThumbnail)
    {
        return self.hasDetail ? HPNoteTableViewCellLayoutModeDetailThumbnail : HPNoteTableViewCellLayoutModeThumbnail;
    }
    return self.hasDetail ? HPNoteTableViewCellLayoutModeDetail : HPNoteTableViewCellLayoutModeDefault;
}

- (void)displayDetail
{
    self.detailLabel.hidden = !self.hasDetail;
    self.detailLabel.font = [[HPFontManager sharedManager] fontForDetail];
    NSString *detailText = @"";
    switch (self.detailMode)
    {
        case HPTagSortModeModifiedAt:
            detailText = self.note.modifiedAtDescription;
            break;
        case HPTagSortModeTag:
            detailText = self.note.firstTagName ? : NSLocalizedString(@"untagged", @"");
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
    [self invalidateConstraintsIfNeeded];
}

- (BOOL)hasDetail
{
    switch (self.detailMode) {
        case HPTagSortModeModifiedAt:
        case HPTagSortModeTag:
            return YES;
        default:
            return NO;
    }
}

- (void)invalidateConstraints
{
    [self.contentView removeConstraint:self.detailLabelTrailingSpaceConstraint];
    [self.contentView removeConstraint:self.titleLabelTrailingSpaceConstraint];
    [self.contentView removeConstraints:_titleDetailConstraints];
    [self.contentView removeConstraints:_thumbnailTitleConstraints];
    [self.contentView removeConstraints:_thumbnailDetailConstraints];
    [self.contentView removeConstraint:self.bodyLabelAlignRightToTitleConstraint];
    [self.contentView removeConstraint:_bodyLabelAlignRightToDetailConstraint];
}

- (void)invalidateConstraintsIfNeeded
{
    const HPNoteTableViewCellLayoutMode previousLayoutMode = _layoutMode;
    _layoutMode = [self calculateLayoutMode];
    if (_layoutMode != previousLayoutMode)
    {
        [self invalidateConstraints];
        [self setNeedsUpdateConstraints];
    }
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

- (void)setDetailMode:(HPTagSortMode)detailMode
{
    [_modifiedAtSortModeTimer invalidate];
    _detailMode = detailMode;
    [self displayDetail];
    if (_detailMode == HPTagSortModeModifiedAt)
    {
        static NSTimeInterval updateDetailDelay = 30;
        _modifiedAtSortModeTimer = [NSTimer scheduledTimerWithTimeInterval:updateDetailDelay target:self selector:@selector(displayDetail) userInfo:nil repeats:YES];
    }
}

- (void)setMargins
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat sideMargin = [HPAgnesUIMetrics sideMarginForInterfaceOrientation:orientation];
    self.titleLabelLeadingSpaceConstraint.constant = sideMargin;
    switch (_layoutMode) {
        case HPNoteTableViewCellLayoutModeDefault:
            self.titleLabelTrailingSpaceConstraint.constant = sideMargin;
            break;
        case HPNoteTableViewCellLayoutModeDetail:
            self.detailLabelTrailingSpaceConstraint.constant = sideMargin;
            break;
        case HPNoteTableViewCellLayoutModeThumbnail:
        case HPNoteTableViewCellLayoutModeDetailThumbnail:
            self.thumbnailViewTrailingSpaceConstraint.constant = sideMargin;
            break;
    }
}

#pragma mark - Actions

- (void)didChangePreferences:(NSNotification*)notification
{
    if (!self.note) return;
    [self applyPreferences];
    [self displayNote];
}

@end
