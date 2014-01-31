//
//  UITableView+hp_reloadChanges.h
//  Agnes
//
//  Created by Hermes on 23/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (hp_reloadChanges)

- (void)hp_reloadChangesWithPreviousData:(NSArray*)previousData
                             currentData:(NSArray*)currentData
                                 keyBlock:(id<NSCopying>(^)(id object))keyBlock
                             reloadBlock:(BOOL(^)(id object))reloadBlock;

@end
