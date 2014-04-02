//
//  HPSectionArrayDataSource.m
//  Agnes
//
//  Created by Hermés Piqué on 02/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPSectionArrayDataSource.h"

@implementation HPSectionArrayDataSource {
    NSMutableArray *_sections;
    NSString *_cellIdentifier;
}

- (instancetype)initWithSections:(NSArray *)sections cellIdentifier:(NSString *)cellIdentifier
{
    if (self = [super init])
    {
        _sections = [sections copy];
        _cellIdentifier = [cellIdentifier copy];
    }
    return self;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *items = _sections[section];
    return items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_cellIdentifier forIndexPath:indexPath];
    id item = [self itemAtIndexPath:indexPath];
    if ([self.delegate respondsToSelector:@selector(dataSource:configureCell:withItem:atIndexPath:)])
    {
        [self.delegate dataSource:self configureCell:cell withItem:item atIndexPath:indexPath];
    }
    return cell;
}

#pragma mark HPDataSource

- (id)itemAtIndexPath:(NSIndexPath*)indexPath
{
    NSArray *items = [self itemsAtSection:indexPath.section];
    const NSUInteger index = indexPath.row;
    id item = items[index];
    return item;
}

- (NSUInteger)itemCount
{
    NSUInteger itemCount = 0;
    for (NSArray *items in _sections)
    {
        itemCount += items.count;
    }
    return itemCount;
}

- (NSArray*)itemsAtSection:(NSUInteger)section
{
    NSArray *items = _sections[section];
    return items;
}

#pragma mark Public

- (NSIndexPath*)indexPathOfItem:(id)item
{
    __block NSIndexPath *indexPath = nil;
    [_sections enumerateObjectsUsingBlock:^(NSArray *items, NSUInteger section, BOOL *stop) {
        const NSUInteger row = [items indexOfObject:item];
        if (row != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:row inSection:section];
        }
    }];
    return indexPath;
}

@end
