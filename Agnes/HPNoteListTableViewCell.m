//
//  HPNoteListTableViewCell.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteListTableViewCell.h"
#import "HPNote.h"

@implementation HPNoteListTableViewCell {
    NSTimer *_modifiedAtDisplayCriteriaTimer;
    IBOutlet NSLayoutConstraint *_titleLabelTrailingSpaceConstraint;
    NSArray *_firstRowForModifiedAtConstraints;
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
    UIView *titleLabel = self.titleLabel;
    UIView *detailLabel = self.detailLabel;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(titleLabel, detailLabel);
    _firstRowForModifiedAtConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[titleLabel]-8-[detailLabel]" options:0 metrics:nil views:viewsDictionary];
    self.detailLabel.hidden = NO;
}


- (void)dealloc
{
    [_modifiedAtDisplayCriteriaTimer invalidate];
}

- (void)updateConstraints
{
    [super updateConstraints];
    if (self.displayCriteria == HPNoteDisplayCriteriaModifiedAt)
    {
        [self.contentView removeConstraint:_titleLabelTrailingSpaceConstraint];
        [self.contentView addConstraints:_firstRowForModifiedAtConstraints];
    }
    else
    {
        [self.contentView removeConstraints:_firstRowForModifiedAtConstraints];
        [self.contentView addConstraint:_titleLabelTrailingSpaceConstraint];
    }
}

#pragma mark - Public

- (void)setDisplayCriteria:(HPNoteDisplayCriteria)displayCriteria animated:(BOOL)animated
{
    [_modifiedAtDisplayCriteriaTimer invalidate];
    _displayCriteria = displayCriteria;
    [self displayDetail];
    if (_displayCriteria == HPNoteDisplayCriteriaModifiedAt)
    {
        static NSTimeInterval updateDetailDelay = 30;
        _modifiedAtDisplayCriteriaTimer = [NSTimer scheduledTimerWithTimeInterval:updateDetailDelay target:self selector:@selector(displayDetail) userInfo:nil repeats:YES];
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
        [self layoutIfNeeded]; // TODO: Is this necessary?
    }
}

#pragma mark - Private

- (void)displayNote
{
    [super displayNote];
    self.titleLabel.text = self.note.title;
    self.bodyLabel.text = self.note.body;
    [self displayDetail];
}

- (void)displayDetail
{
    NSString *detailText = @"";
    switch (self.displayCriteria)
    {
        case HPNoteDisplayCriteriaModifiedAt:
            detailText = self.note.modifiedAtDescription;
            break;
        default:
            break;
    }
   self.detailLabel.text = detailText;
}

@end
