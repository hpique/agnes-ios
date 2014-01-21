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
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)dealloc
{
    [_modifiedAtDisplayCriteriaTimer invalidate];
}

#pragma mark - Public

- (void)setDisplayCriteria:(HPNoteDisplayCriteria)displayCriteria
{
    [_modifiedAtDisplayCriteriaTimer invalidate];
    _displayCriteria = displayCriteria;
    [self displayDetail];
    if (_displayCriteria == HPNoteDisplayCriteriaModifiedAt)
    {
        static NSTimeInterval updateDetailDelay = 30;
        _modifiedAtDisplayCriteriaTimer = [NSTimer scheduledTimerWithTimeInterval:updateDetailDelay target:self selector:@selector(displayDetail) userInfo:nil repeats:YES];
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
