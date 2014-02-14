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
#import "HPFontManager.h"

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
    _titleView.font = [HPFontManager sharedManager].fontForIndexCellTitle;
    _detailView.font = [HPFontManager sharedManager].fontForIndexCellDetail;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFonts:) name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    if (self.indexItem)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:HPIndexItemDidChangeNotification object:self.indexItem];
    }
}

- (void)prepareForReuse
{
    if (self.indexItem)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:HPIndexItemDidChangeNotification object:self.indexItem];
        _indexItem = nil;
    }
}

- (void)setIndexItem:(HPIndexItem *)indexItem
{
    _indexItem = indexItem;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexItemDidChangeNotification:) name:HPIndexItemDidChangeNotification object:self.indexItem];
    _titleView.text = self.indexItem.indexTitle;
    _iconView.image = self.indexItem.icon;
    _detailView.text = [NSString stringWithFormat:@"%ld", (long)self.indexItem.noteCount];
}

#pragma mark - Notifications

- (void)didChangeFonts:(NSNotification*)notification
{
    _titleView.font = [HPFontManager sharedManager].fontForIndexCellTitle;
    _detailView.font = [HPFontManager sharedManager].fontForIndexCellDetail;
}

- (void)indexItemDidChangeNotification:(NSNotification*)notification
{
    if (self.indexItem)
    {
        _iconView.image = self.indexItem.icon;
        _detailView.text = [NSString stringWithFormat:@"%ld", (long)self.indexItem.noteCount];
    }
}

@end
