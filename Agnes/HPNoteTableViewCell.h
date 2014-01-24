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
@class TTTAttributedLabel;

extern NSInteger const HPNotTableViewCellLabelMaxLength;

@interface HPNoteTableViewCell : MCSwipeTableViewCell

@property (nonatomic, strong) HPNote *note;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *titleLabel;
@property (weak, nonatomic) IBOutlet TTTAttributedLabel *bodyLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topVerticalSpaceConstraint;

- (void)displayNote;

+ (CGFloat)heightForNote:(HPNote*)note width:(CGFloat)width;

@end
