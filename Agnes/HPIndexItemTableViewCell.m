//
//  HPIndexItemTableViewCell.m
//  Agnes
//
//  Created by Hermes on 24/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPIndexItemTableViewCell.h"
#import "HPIndexItem.h"

@implementation HPIndexItemTableViewCell
{
    __weak IBOutlet UILabel *_detailView;
    __weak IBOutlet UILabel *_titleView;
    __weak IBOutlet UIImageView *_iconView;
}

- (void)setIndexItem:(HPIndexItem *)indexItem
{
    _indexItem = indexItem;
    _titleView.text = self.indexItem.indexTitle;
    _iconView.image = self.indexItem.icon;
    _detailView.text = [NSString stringWithFormat:@"%ld", (long)self.indexItem.notes.count];
}

@end
