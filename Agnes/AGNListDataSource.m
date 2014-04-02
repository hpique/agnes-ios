//
//  AGNListDataSource.m
//  Agnes
//
//  Created by Hermés Piqué on 02/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNListDataSource.h"

@implementation AGNListDataSource

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.delegate canMoveItemsInDataSource:self];
}

@end
