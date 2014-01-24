//
//  HPIndexItemTableViewCell.m
//  Agnes
//
//  Created by Hermes on 24/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPIndexItemTableViewCell.h"
#import "HPIndexItem.h"
#import "HPNoteManager.h"

@implementation HPIndexItemTableViewCell
{
    __weak IBOutlet UILabel *_detailView;
    __weak IBOutlet UILabel *_titleView;
    __weak IBOutlet UIImageView *_iconView;
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectsDidChange:) name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
}

- (void)setIndexItem:(HPIndexItem *)indexItem
{
    _indexItem = indexItem;
    _titleView.text = self.indexItem.indexTitle;
    _iconView.image = self.indexItem.icon;
    _detailView.text = [NSString stringWithFormat:@"%ld", (long)self.indexItem.notes.count];
}

#pragma mark - Private

- (void)objectsDidChange:(NSNotification*)notification
{
    if (self.indexItem)
    {
        _iconView.image = self.indexItem.icon;
        _detailView.text = [NSString stringWithFormat:@"%ld", (long)self.indexItem.notes.count];        
    }
}

@end
