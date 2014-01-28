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

extern NSInteger const HPNotTableViewCellLabelMaxLength;

@interface HPNoteTableViewCell : MCSwipeTableViewCell

@property (nonatomic, strong) HPNote *note;

/** Needs to be set before the note. */
@property (nonatomic, copy) NSString *tagName;

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@property (weak, nonatomic) IBOutlet UILabel *bodyLabel;

@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topVerticalSpaceConstraint;

- (void)displayNote;

+ (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width tagName:(NSString*)tagName;

@end

@interface HPNoteTableViewCell(Subclassing)

- (void)initHelper;

- (void)applyPreferences;

@end