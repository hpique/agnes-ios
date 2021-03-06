//
//  HPNoteTableViewCell.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteTableViewCell.h"
#import "HPNote.h"
#import "HPNote+List.h"
#import "HPFontManager.h"
#import "AGNPreferencesManager.h"
#import "HPAgnesImageCache.h"
#import "AGNUIMetrics.h"
#import "HPAttachment.h"
#import "NSString+hp_utils.h"
#import "UIColor+hp_utils.h"
#import "UIImageView+Haneke.h"
#import "HPAgnesImageCache.h"
#import "UILabel+hp_utils.h"
#import <Lyt/Lyt.h>

NSInteger const HPNoteTableViewCellLabelMaxLength = 150;
CGFloat const HPNoteTableViewCellMargin = 10;
CGFloat const HPNoteTableViewCellThumbnailMarginLeading = 8;
NSUInteger const HPNoteTableViewCellLineCount = 3;

static NSString *const HPNoteHeightCacheIsTruncatedSummaryPrefix = @"s";

@interface HPNoteHeightCache : NSObject

- (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width kind:(NSString*)kind;

- (void)invalidateCache;

- (void)setHeight:(CGFloat)height forNote:(HPNote*)note width:(CGFloat)width kind:(NSString*)kind;

- (NSNumber*)isTruncatedSummaryForNote:(HPNote*)note width:(CGFloat)width tagName:(NSString*)tagName;

- (void)setIsTruncatedSummary:(BOOL)isTruncatedSummary forNote:(HPNote*)note width:(CGFloat)width tagName:(NSString*)tagName;

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

- (NSString*)keyForWidth:(CGFloat)width kind:(NSString*)kind
{
    static NSString *const KeyFormat = @"%d%@";
    return [NSString stringWithFormat:KeyFormat, (int)width, kind];
}

- (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width kind:(NSString*)kind
{
    NSDictionary *dictionary = [_cache objectForKey:note.uuid];
    NSString *key = [self keyForWidth:width kind:kind];
    NSNumber *value = dictionary[key];
    return value ? [value floatValue] : 0;
}

- (void)invalidateCache
{
    [_cache removeAllObjects];
}

- (void)setHeight:(CGFloat)height forNote:(HPNote*)note width:(CGFloat)width kind:(NSString*)kind
{
    NSDictionary *dictionary = [_cache objectForKey:note.uuid];
    if (!dictionary) dictionary = [NSDictionary dictionary];
    NSMutableDictionary *updatedDictionary = dictionary.mutableCopy;
    NSString *key = [self keyForWidth:width kind:kind];
    updatedDictionary[key] = @(height);
    [_cache setObject:updatedDictionary forKey:note.uuid];
}

- (NSNumber*)isTruncatedSummaryForNote:(HPNote*)note width:(CGFloat)width tagName:(NSString*)tagName
{
    NSDictionary *dictionary = [_cache objectForKey:note.uuid];
    NSString *kind = [HPNoteHeightCacheIsTruncatedSummaryPrefix stringByAppendingString:tagName];
    NSString *key = [self keyForWidth:width kind:kind];
    NSNumber *value = dictionary[key];
    return value;
}

- (void)setIsTruncatedSummary:(BOOL)isTruncatedSummary forNote:(HPNote*)note width:(CGFloat)width tagName:(NSString*)tagName
{
    NSDictionary *dictionary = [_cache objectForKey:note.uuid];
    if (!dictionary) dictionary = [NSDictionary dictionary];
    NSMutableDictionary *updatedDictionary = dictionary.mutableCopy;
    NSString *kind = [HPNoteHeightCacheIsTruncatedSummaryPrefix stringByAppendingString:tagName];
    NSString *key = [self keyForWidth:width kind:kind];
    updatedDictionary[key] = @(isTruncatedSummary);
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
    if (notification.hp_invalidatedAllObjects)
    {
        [_cache removeAllObjects];
        return;
    }
    NSDictionary *userInfo = notification.userInfo;
    {
        NSSet *updated = [userInfo objectForKey:NSUpdatedObjectsKey];
        NSString *textKey = NSStringFromSelector(@selector(text));
        for (HPNote *note in updated)
        { // Only invalidate notes whose text changed
            id value = [note.changedValuesForCurrentEvent objectForKey:textKey];
            if (value)
            {
                [_cache removeObjectForKey:note.uuid];
            }
        }
    }
    {
        NSSet *inserted = [userInfo objectForKey:NSInsertedObjectsKey];
        NSSet *deleted = [userInfo objectForKey:NSDeletedObjectsKey];
        NSSet *invalidated = [userInfo objectForKey:NSInvalidatedObjectsKey];
        NSSet *refreshed = [userInfo objectForKey:NSRefreshedObjectsKey];
        NSMutableSet *otherChanges = [NSMutableSet set];
        [otherChanges unionSet:inserted];
        [otherChanges unionSet:deleted];
        [otherChanges unionSet:invalidated];
        [otherChanges unionSet:refreshed];
        for (HPNote *note in otherChanges)
        {
            [_cache removeObjectForKey:note.uuid];
        }
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
    NSLayoutConstraint *_titleDetailConstraint;
    NSLayoutConstraint *_thumbnailDetailConstraint;
    NSLayoutConstraint *_thumbnailTitleConstraint;
    NSLayoutConstraint *_bodyLabelAlignRightToDetailConstraint;
    NSTimer *_modifiedAtSortModeTimer;
    HPNoteTableViewCellLayoutMode _layoutMode;
}

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:AGNPreferencesManagerDidChangePreferencesNotification object:[AGNPreferencesManager sharedManager]];
    
    {
        _titleDetailConstraint = [_detailLabel lyt_constraintByPlacingRightOfView:_titleLabel margin:8];
        _thumbnailDetailConstraint = [_thumbnailView lyt_constraintByPlacingRightOfView:_detailLabel margin:8];
        _thumbnailTitleConstraint = [_thumbnailView lyt_constraintByPlacingRightOfView:_titleLabel margin:8];
        _bodyLabelAlignRightToDetailConstraint = [_bodyLabel lyt_constraintByAligningRightToView:_detailLabel];
        
        self.thumbnailViewWidthConstraint.constant = [HPNoteTableViewCell thumbnailViewWidth];
        self.thumbnailViewHeightConstraint.constant = self.thumbnailViewWidthConstraint.constant;
    }
    
    _layoutMode = HPNoteTableViewCellLayoutModeDefault;
    
    self.thumbnailView.layer.borderWidth = 1;
    UIColor *separatorColor = [UIColor colorWithWhite:0.90 alpha:1];
    self.thumbnailView.layer.borderColor = separatorColor.CGColor;
    self.thumbnailView.hnk_cacheFormat = [HPAgnesImageCache sharedCache].thumbnailFormat;

    [self applyPreferences];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AGNPreferencesManagerDidChangePreferencesNotification object:[AGNPreferencesManager sharedManager]];
    [self removeNoteObserver];
    [_modifiedAtSortModeTimer invalidate];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == HPNoteTableViewCellContext)
    {
        if (self.note.managedObjectContext && self.agnesTag.managedObjectContext)
        {
            [self displayNote];
        }
        else
        {
            [self prepareForReuse];
        }
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
    const CGFloat width = self.contentView.bounds.size.width;
    const CGFloat titleWidth = [self.class widthForTitleOfNote:self.note cellWidth:width];
    _titleLabel.preferredMaxLayoutWidth = titleWidth;
    _bodyLabel.preferredMaxLayoutWidth = titleWidth;
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
            [self.contentView addConstraint:_titleDetailConstraint];
            [self.contentView addConstraint:_bodyLabelAlignRightToDetailConstraint];
            break;
        case HPNoteTableViewCellLayoutModeThumbnail:
            [self.contentView addConstraint:self.bodyLabelAlignRightToTitleConstraint];
            [self.contentView addConstraint:_thumbnailTitleConstraint];
            break;
        case HPNoteTableViewCellLayoutModeDetailThumbnail:
            [self.contentView addConstraint:_titleDetailConstraint];
            [self.contentView addConstraint:_bodyLabelAlignRightToDetailConstraint];
            [self.contentView addConstraint:_thumbnailDetailConstraint];
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
    _note = nil;
    self.thumbnailView.image = nil;
    _agnesTag = nil;
    self.thumbnailView.hidden = YES;
}

#pragma mark Public

- (BOOL)isTruncatedSummary
{
    HPNoteHeightCache *cache = [HPNoteHeightCache sharedCache];
    HPNote *note = self.note;
    HPTag *tag = self.agnesTag;
    const CGFloat width = self.contentView.bounds.size.width;
    NSNumber *value = [cache isTruncatedSummaryForNote:note width:width tagName:tag.name];
    if (value) return [value boolValue];
    
    // If the cache was invalidated, recalculate
    const CGFloat titleWidth = [HPNoteTableViewCell widthForTitleOfNote:note cellWidth:width];
    [HPNoteTableViewCell heightForSummaryOfNote:note cellWidth:width summaryWidth:titleWidth titleLines:self.titleLabel.numberOfLines tag:tag];
    value = [cache isTruncatedSummaryForNote:note width:width tagName:tag.name];

    return [value boolValue];
}

- (void)setNote:(HPNote *)note ofTag:(HPTag*)agnesTag detailMode:(HPTagSortMode)detailMode
{
    [self removeNoteObserver];
    _note = note;
    _agnesTag = agnesTag;
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

- (NSString*)bodyForTransition
{
    NSString *visibleBody = [self.bodyLabel hp_visibleText];
    return visibleBody;
}

- (NSString*)titleForTransition
{
    NSString *visibleTitle = [self.titleLabel hp_visibleText];
    return visibleTitle;
}

+ (CGFloat)estimatedHeightForNote:(HPNote*)note width:(CGFloat)width inTag:(HPTag*)tag
{
    CGFloat estimatedHeight = [[HPNoteHeightCache sharedCache] heightForNote:note width:(CGFloat)width kind:tag.name];
    if (estimatedHeight > 0) return estimatedHeight;
    
    estimatedHeight = HPNoteTableViewCellMargin * 2;
    if (note.mightHaveThumbnail)
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

+ (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width tag:(HPTag*)tag
{
    CGFloat cachedHeight = [[HPNoteHeightCache sharedCache] heightForNote:note width:width kind:tag.name];
    if (cachedHeight > 0) return cachedHeight;

    HPFontManager *fonts = [HPFontManager sharedManager];
    
    UIFont *titleFont = [fonts fontForTitleOfNote:note];
    const CGFloat titleWidth = [self widthForTitleOfNote:note cellWidth:width];
    const CGFloat titleLineHeight = fonts.noteTitleLineHeight;
    NSUInteger titleLines = [note.title hp_linesWithFont:titleFont width:titleWidth lineHeight:titleLineHeight];
    titleLines = MIN(HPNoteTableViewCellLineCount, titleLines);

    const CGFloat summaryHeight = [self heightForSummaryOfNote:note cellWidth:width summaryWidth:titleWidth titleLines:titleLines tag:tag];
    CGFloat height = titleLines * titleLineHeight + summaryHeight + HPNoteTableViewCellMargin * 2;
    
    const BOOL hasThumbnail = note.hasThumbnail;
    height = hasThumbnail ? MAX([self thumbnailViewWidth] + HPNoteTableViewCellMargin * 2, height) : height;
    [[HPNoteHeightCache sharedCache] setHeight:height forNote:note width:width kind:tag.name];
    return height;
}

+ (CGFloat)heightForSummaryOfNote:(HPNote*)note cellWidth:(CGFloat)cellWidth summaryWidth:(CGFloat)summaryWidth titleLines:(NSUInteger)titleLines tag:(HPTag*)tag
{
    HPFontManager *fonts = [HPFontManager sharedManager];
    UIFont *bodyFont = [fonts fontForBodyOfNote:note];
    const CGFloat bodyLineHeight = fonts.noteBodyLineHeight;
    NSString *summary = [note summaryForTag:tag];
    NSUInteger summaryLines = summary.length > 0 ? [summary hp_linesWithFont:bodyFont width:summaryWidth lineHeight:bodyLineHeight] : 0;
    const NSUInteger maximumSummaryLines = HPNoteTableViewCellLineCount - titleLines;
    summaryLines = MAX(0, MIN(maximumSummaryLines, summaryLines));
    
    HPNoteHeightCache *cache = [HPNoteHeightCache sharedCache];
    const BOOL isTruncatedSummary = summaryLines > maximumSummaryLines;
    [cache setIsTruncatedSummary:isTruncatedSummary forNote:note width:cellWidth tagName:tag.name];
    
    const CGFloat summaryHeight = summaryLines * bodyLineHeight;
    return summaryHeight;
}

+ (void)invalidateHeightCache
{
    [[HPNoteHeightCache sharedCache] invalidateCache];
}

+ (CGFloat)thumbnailViewWidth
{
    return [HPFontManager sharedManager].noteTitleLineHeight * HPNoteTableViewCellLineCount;
}

+ (CGFloat)widthForTitleOfNote:(HPNote*)note cellWidth:(CGFloat)cellWidth
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat width = cellWidth - [AGNUIMetrics sideMarginForInterfaceOrientation:orientation width:cellWidth] * 2;
    if (note.hasThumbnail)
    {
        width -= HPNoteTableViewCellThumbnailMarginLeading + [self thumbnailViewWidth];
    }
    return width;
}

#pragma mark - Private

- (void)applyPreferences {}

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
        case HPTagSortModeViews:
            detailText = [NSString localizedStringWithFormat:NSLocalizedString(@"%ld views", @""), (long)self.note.views];
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
        self.thumbnailView.image = nil;
        HPAttachment *thumbnailAttachment = self.note.thumbnailAttachment;
        [self.thumbnailView hnk_setImageFromEntity:thumbnailAttachment];
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
        case HPTagSortModeViews:
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
    [self.contentView removeConstraint:_titleDetailConstraint];
    [self.contentView removeConstraint:_thumbnailTitleConstraint];
    [self.contentView removeConstraint:_thumbnailDetailConstraint];
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
    CGFloat sideMargin = [AGNUIMetrics sideMarginForInterfaceOrientation:orientation width:self.bounds.size.width];
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
