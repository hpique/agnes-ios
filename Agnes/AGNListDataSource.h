//
//  AGNListDataSource.h
//  Agnes
//
//  Created by Hermés Piqué on 02/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPArrayDataSource.h"

@protocol AGNListDataSourceDelegate <HPArrayDataSourceDelegate>

- (BOOL)canMoveItemsInDataSource:(HPArrayDataSource*)dataSource;

@end

@interface AGNListDataSource : HPArrayDataSource

@property (nonatomic, weak) id<AGNListDataSourceDelegate> delegate;

@end
