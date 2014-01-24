//
//  UITableView+hp_reloadChanges.m
//  Agnes
//
//  Created by Hermes on 23/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UITableView+hp_reloadChanges.h"

@implementation UITableView (hp_reloadChanges)

- (void)hp_reloadChangesWithPreviousData:(NSArray*)previousData
                             currentData:(NSArray*)currentData
                                 keyBlock:(id<NSCopying>(^)(id object))keyBlock
{
    if (!previousData || previousData.count != currentData.count)
    {
        [self reloadData];
        return;
    }
    NSInteger sectionCount = [self.dataSource numberOfSectionsInTableView:self];
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    NSMutableArray *indexPathsToMove = [NSMutableArray array];
    for (NSInteger sectionIndex = 0; sectionIndex < sectionCount; sectionIndex++)
    {
        NSArray *previousObjects = previousData[sectionIndex];
        NSArray *currentObjects = currentData[sectionIndex];
        NSDictionary *previousIndexes = [UITableView dictionaryWithIndexesOfObjects:previousObjects keyBlock:keyBlock];
        NSDictionary *currentIndexes = [UITableView dictionaryWithIndexesOfObjects:currentObjects keyBlock:keyBlock];
        
        [previousObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             id<NSCopying> key = keyBlock(obj);
             if (![currentIndexes objectForKey:key])
             {
                 NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:sectionIndex];
                 [indexPathsToDelete addObject:indexPath];
             }
         }];
        
        [currentObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             id<NSCopying> key = keyBlock(obj);
             NSNumber *indexNumber = [previousIndexes objectForKey:key];
             if (!indexNumber)
             {
                 NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:sectionIndex];
                 [indexPathsToInsert addObject:indexPath];
             }
             else
             {
                 NSInteger previousIndex = [indexNumber integerValue];
                 if (previousIndex != idx)
                 {
                     NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:previousIndex inSection:sectionIndex];
                     NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:idx inSection:sectionIndex];
                     [indexPathsToMove addObject:@[fromIndexPath, toIndexPath]];
                 }
             }
         }];
    }
    
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

#pragma mark - Private

+ (NSDictionary*)dictionaryWithIndexesOfObjects:(NSArray*)objects keyBlock:(id<NSCopying>(^)(id object))keyBlock
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<NSCopying> key = keyBlock(obj);
        [dictionary setObject:@(idx) forKey:key];
    }];
    return dictionary;
}

@end
