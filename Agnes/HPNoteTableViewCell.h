//
//  HPNoteTableViewCell.h
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCSwipeTableViewCell.h"
@class HPNote;
#import "HPTag.h"

extern NSInteger const HPNoteTableViewCellLabelMaxLength;
extern CGFloat const HPNoteTableViewCellMargin;
extern NSUInteger const HPNoteTableViewCellLineCount;

@interface HPNoteTableViewCell : MCSwipeTableViewCell

@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleLabelTrailingSpaceConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *detailLabelTrailingSpaceConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bodyLabelAlignRightToTitleConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *thumbnailViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *thumbnailViewHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleLabelLeadingSpaceConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *thumbnailViewTrailingSpaceConstraint;

@property (nonatomic, readonly) HPTag *agnesTag;
@property (nonatomic, readonly) HPTagSortMode detailMode;
@property (nonatomic, readonly) BOOL isTruncatedSummary;
@property (nonatomic, readonly) HPNote *note;

@property (nonatomic, readonly) NSString *bodyForTransition;
@property (nonatomic, readonly) NSString *titleForTransition;

- (void)setNote:(HPNote *)note ofTag:(HPTag*)agnesTag detailMode:(HPTagSortMode)detailMode;

- (void)setDetailMode:(HPTagSortMode)detailMode animated:(BOOL)animated;

- (void)displayNote;

+ (CGFloat)estimatedHeightForNote:(HPNote*)note width:(CGFloat)width inTag:(HPTag*)tag;

+ (void)invalidateHeightCache;

+ (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width tag:(HPTag*)tag;

+ (CGFloat)thumbnailViewWidth;

+ (CGFloat)widthForTitleOfNote:(HPNote*)note cellWidth:(CGFloat)cellWidth;

@end

@interface HPNoteTableViewCell(Subclassing)

- (void)initHelper;

- (void)applyPreferences;

@end
