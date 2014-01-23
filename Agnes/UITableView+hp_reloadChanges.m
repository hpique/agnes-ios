//
//  UITableView+hp_reloadChanges.m
//  Agnes
//
//  Created by Hermes on 23/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UITableView+hp_reloadChanges.h"

@implementation UITableView (hp_reloadChanges)

- (void)hp_reloadChangesInSection:(NSUInteger)section previousData:(NSArray*)previousData updatedData:(NSArray*)updatedData
{
    if (!previousData)
    {
        [self reloadData];
        return;
    }
    
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    [previousData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         // TODO: Use dictionaries
         if (![updatedData containsObject:obj])
         {
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:section];
             [indexPathsToDelete addObject:indexPath];
         }
     }];
    
    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    NSMutableArray *indexPathsToMove = [NSMutableArray array];
    [updatedData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         // TODO: Use dictionaries
         NSUInteger previousIndex = [previousData indexOfObject:obj];
         if (previousIndex == NSNotFound)
         {
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:section];
             [indexPathsToInsert addObject:indexPath];
         }
         else if (previousIndex != idx)
         {
             NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:previousIndex inSection:section];
             NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:idx inSection:section];
             [indexPathsToMove addObject:@[fromIndexPath, toIndexPath]];
         }
     }];
    
    if (indexPathsToDelete.count > 0 || indexPathsToMove.count > 0 || indexPathsToInsert.count > 0)
    {
        [self beginUpdates];
        [self deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
        for (NSArray *indexPaths in indexPathsToMove)
        {
            [self moveRowAtIndexPath:indexPaths[0] toIndexPath:indexPaths[1]];
        }
        [self insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
        [self endUpdates];
    }
}

@end
