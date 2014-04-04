//
//  HPArrayDataSource.m
//  Agnes
//
//  Created by Hermés Piqué on 02/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPArrayDataSource.h"

@implementation HPArrayDataSource {
    NSMutableArray *_mutableItems;
}

- (instancetype)init
{
    return [self initWithItems:@[] cellIdentifier:nil configureCellBlock:nil];
}

- (instancetype)initWithItems:(NSArray *)items cellIdentifier:(NSString *)cellIdentifier
{
    return [self initWithItems:items cellIdentifier:cellIdentifier configureCellBlock:nil];
}

- (instancetype)initWithItems:(NSArray *)items cellIdentifier:(NSString *)cellIdentifier configureCellBlock:(HPArrayDataSourceConfigureCellBlock)configureCellBlock
{
    if (self = [super init])
    {
        _mutableItems = [items mutableCopy];
        _cellIdentifier = [cellIdentifier copy];
        _configureCellBlock = [configureCellBlock copy];
    }
    return self;
}

#pragma mark Public

- (NSUInteger)indexOfItem:(id)item
{
    return [_mutableItems indexOfObject:item];
}

- (void)removeItemAtIndex:(NSUInteger)index
{
    [_mutableItems removeObjectAtIndex:index];
}

#pragma mark Properties

- (void)setItems:(NSArray *)items
{
    _mutableItems = [items mutableCopy];
}

- (NSArray*)items
{
    return [_mutableItems copy];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self itemCount];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:_cellIdentifier forIndexPath:indexPath];
    const NSUInteger index = indexPath.row;
    id item = _mutableItems[index];
    if (_configureCellBlock)
    {
        _configureCellBlock(cell, item, index);
    }
    if ([self.delegate respondsToSelector:@selector(dataSource:configureCell:withItem:atIndex:)])
    {
        [self.delegate dataSource:self configureCell:cell withItem:item atIndex:index];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    const NSUInteger sourceIndex = sourceIndexPath.row;
    const NSUInteger destinationIndex = destinationIndexPath.row;
    if ([self.delegate respondsToSelector:@selector(dataSource:willMoveItemAtIndex:toIndex:)])
    {
        [self.delegate dataSource:self willMoveItemAtIndex:sourceIndex toIndex:destinationIndex];
    }
    [_mutableItems exchangeObjectAtIndex:sourceIndex withObjectAtIndex:destinationIndex];
    if ([self.delegate respondsToSelector:@selector(dataSource:didMoveItemAtIndex:toIndex:)])
    {
        [self.delegate dataSource:self didMoveItemAtIndex:sourceIndex toIndex:destinationIndex];
    }
}

#pragma mark HPDataSource

- (id)itemAtIndexPath:(NSIndexPath*)indexPath
{
    const NSUInteger index = indexPath.row;
    id item = _mutableItems[index];
    return item;
}

- (NSUInteger)itemCount
{
    return _mutableItems.count;
}

- (NSArray*)itemsAtSection:(NSUInteger)section
{
    return _mutableItems;
}

@end
