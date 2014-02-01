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
extern CGFloat const HPNoteTableViewCellImageHeight;

@interface HPNoteTableViewCell : MCSwipeTableViewCell

@property (nonatomic, strong) HPNote *note;

@property (nonatomic, readonly) HPTagSortMode sortMode;

- (void)setSortMode:(HPTagSortMode)sortMode animated:(BOOL)animated;

/** Needs to be set before the note. */
@property (nonatomic, copy) NSString *tagName;

@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;

@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@property (weak, nonatomic) IBOutlet UIImageView *thumbnailView;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleLabelTrailingSpaceConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *detailLabelTrailingSpaceConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bodyLabelRightConstraint;


- (void)displayNote;

+ (CGFloat)estimatedHeightForNote:(HPNote*)note;

+ (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width tagName:(NSString*)tagName;

@end

@interface HPNoteTableViewCell(Subclassing)

- (void)initHelper;

- (void)applyPreferences;

@end