//
//  UITableView+hp_reloadChanges.m
//  Agnes
//
//  Created by Hermes on 23/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "UITableView+hp_reloadChanges.h"

const NSUInteger HPTableViewMaxChangesWithoutFullReload = 20;

@implementation UITableView (hp_reloadChanges)

- (void)hp_reloadChangesWithPreviousData:(NSArray*)previousData
                             currentData:(NSArray*)currentData
                                keyBlock:(id<NSCopying>(^)(id object))keyBlock
                             reloadBlock:(BOOL(^)(id object))reloadBlock
{
    if (!previousData || previousData.count != currentData.count)
    {
        [self reloadData];
        return;
    }
    NSInteger sectionCount = [self.dataSource respondsToSelector:@selector(numberOfSectionsInTableView:)] ? [self.dataSource numberOfSectionsInTableView:self] : 1;
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    NSMutableArray *indexPathsToMove = [NSMutableArray array];
    NSMutableArray *indexPathsToReload = [NSMutableArray array];
    __block NSUInteger changeCount = 0;
    for (NSInteger sectionIndex = 0; sectionIndex < sectionCount && changeCount <= HPTableViewMaxChangesWithoutFullReload; sectionIndex++)
    {
        NSArray *previousObjects = previousData[sectionIndex];
        NSArray *currentObjects = currentData[sectionIndex];
        NSDictionary *previousIndexes = [UITableView hp_dictionaryWithIndexesOfObjects:previousObjects keyBlock:keyBlock];
        NSDictionary *currentIndexes = [UITableView hp_dictionaryWithIndexesOfObjects:currentObjects keyBlock:keyBlock];
        
        [previousObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             id<NSCopying> key = keyBlock(obj);
             if (![currentIndexes objectForKey:key])
             {
                 NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:sectionIndex];
                 [indexPathsToDelete addObject:indexPath];
                 changeCount++;
                 if (changeCount > HPTableViewMaxChangesWithoutFullReload)
                 {
                     *stop = YES;
                     return;
                 }
                 
             }
         }];
        
        if (changeCount > HPTableViewMaxChangesWithoutFullReload)
        {
            break;
        }
        
        [currentObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
         {
             id<NSCopying> key = keyBlock(obj);
             NSNumber *indexNumber = [previousIndexes objectForKey:key];
             if (!indexNumber)
             {
                 NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:sectionIndex];
                 [indexPathsToInsert addObject:indexPath];
                 changeCount++;
                 if (changeCount > HPTableViewMaxChangesWithoutFullReload)
                 {
                     *stop = YES;
                     return;
                 }
             }
             else
             {
                 NSInteger previousIndex = [indexNumber integerValue];
                 if (previousIndex != idx)
                 {
                     NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:previousIndex inSection:sectionIndex];
                     NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:idx inSection:sectionIndex];
                     [indexPathsToMove addObject:@[fromIndexPath, toIndexPath]];
                     changeCount++;
                     if (changeCount > HPTableViewMaxChangesWithoutFullReload)
                     {
                         *stop = YES;
                         return;
                     }
                 }
                 else
                 {
                     if (reloadBlock)
                     {
                         BOOL reload = reloadBlock(obj);
                         if (reload)
                         {
                             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:previousIndex inSection:sectionIndex];
                             [indexPathsToReload addObject:indexPath];
                             changeCount++;
                             if (changeCount > HPTableViewMaxChangesWithoutFullReload)
                             {
                                 *stop = YES;
                                 return;
                             }
                         }
                     }
                 }
             }
         }];
    }
    
    if (changeCount > HPTableViewMaxChangesWithoutFullReload)
    {
        [self reloadData];
    }
    else if (changeCount > 0)
    {
        [self beginUpdates];
        [self deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
        for (NSArray *indexPaths in indexPathsToMove)
        {
            [self moveRowAtIndexPath:indexPaths[0] toIndexPath:indexPaths[1]];
        }
        [self reloadRowsAtIndexPaths:indexPathsToReload withRowAnimation:UITableViewRowAnimationAutomatic];
        [self insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
        [self endUpdates];
    }
}


#pragma mark - Private

+ (NSDictionary*)hp_dictionaryWithIndexesOfObjects:(NSArray*)objects keyBlock:(id<NSCopying>(^)(id object))keyBlock
{
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    [objects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id<NSCopying> key = keyBlock(obj);
        [dictionary setObject:@(idx) forKey:key];
    }];
    return dictionary;
}

@end
