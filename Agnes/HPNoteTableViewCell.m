//
//  HPNoteTableViewCell.m
//  Agnes
//
//  Created by Hermes on 17/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteTableViewCell.h"
#import "HPNote.h"

static void *HPNoteTableViewCellContext = &HPNoteTableViewCellContext;

@implementation HPNoteTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)dealloc
{
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(body))];
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

#pragma mark - Public

- (void)setNote:(HPNote *)note
{
    [_note removeObserver:self forKeyPath:NSStringFromSelector(@selector(body))];
    _note = note;
    
    [self.note addObserver:self forKeyPath:NSStringFromSelector(@selector(body)) options:NSKeyValueObservingOptionNew context:HPNoteTableViewCellContext];
    [self displayNote];
}

#pragma mark - Private

- (void)displayNote
{
    self.textLabel.text = self.note.title;
}


@end
