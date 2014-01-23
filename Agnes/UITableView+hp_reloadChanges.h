//
//  UITableView+hp_reloadChanges.h
//  Agnes
//
//  Created by Hermes on 23/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (hp_reloadChanges)

- (void)hp_reloadChangesInSection:(NSUInteger)section previousData:(NSArray*)previousData updatedData:(NSArray*)updatedData;

@end
