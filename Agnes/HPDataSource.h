//
//  HPDataSource.h
//  Agnes
//
//  Created by Hermés Piqué on 02/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

@import UIKit;

@protocol HPDataSource <UITableViewDataSource>

- (id)itemAtIndexPath:(NSIndexPath*)indexPath;

- (NSUInteger)itemCount;

- (NSArray*)itemsAtSection:(NSUInteger)section;

@end
