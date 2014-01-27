//
//  HPNoteListTableViewCell.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteListTableViewCell.h"
#import "HPNote.h"
#import "TTTAttributedLabel.h"
#import "HPPreferencesManager.h"

@interface HPNoteListTableViewCell()

@property (nonatomic, weak) TTTAttributedLabel *titleLabel;
@property (nonatomic, weak) TTTAttributedLabel *bodyLabel;

@end

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
    
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    NSDictionary *highlightedAttributes = @{ NSForegroundColorAttributeName : preferences.tintColor };
    self.titleLabel.truncationTokenStringAttributes = highlightedAttributes;
    self.bodyLabel.truncationTokenStringAttributes =  highlightedAttributes;
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
        [self setNeedsLayout];
    }
}

#pragma mark - HPNoteTableViewCell

- (void)displayNote
{
    [super displayNote];
    NSString *title = self.note.title;
    if (title)
    {
        [self setHighlightedText:self.note.title inLabel:self.titleLabel];
    }
    else
    { // KVO notifies nil property changes after note is deleted
        self.titleLabel.text = nil;
    }
    NSString *bodyForTag = [self.note bodyForTagWithName:self.tagName];
    if (bodyForTag)
    {
        [self setHighlightedText:bodyForTag inLabel:self.bodyLabel];
    }
    else
    {
        self.bodyLabel.text = nil;
    }
    [self displayDetail];
}

#pragma mark - Private

- (void)setHighlightedText:(NSString*)text inLabel:(TTTAttributedLabel*)label
{
    [label setText:text afterInheritingLabelAttributesAndConfiguringWithBlock:^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString) {
        HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
        NSRegularExpression* regex = [HPNote tagRegularExpression];
        NSDictionary* attributes = @{ NSForegroundColorAttributeName : preferences.tintColor };
        
        NSInteger maxLength = MIN(HPNotTableViewCellLabelMaxLength, text.length);
        [regex enumerateMatchesInString:text
                                options:0
                                  range:NSMakeRange(0, maxLength)
                             usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
         {
             NSRange matchRange = [match rangeAtIndex:0];
             [mutableAttributedString addAttributes:attributes range:matchRange];
         }];
        return mutableAttributedString;
    }];
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
