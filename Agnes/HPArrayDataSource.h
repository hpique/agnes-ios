//
//  HPArrayDataSource.h
//  Agnes
//
//  Created by Hermés Piqué on 02/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPDataSource.h"

typedef void (^HPArrayDataSourceConfigureCellBlock)(id cell, id item, NSUInteger idx);

@protocol HPArrayDataSourceDelegate;

@interface HPArrayDataSource : NSObject<HPDataSource>

- (instancetype)initWithItems:(NSArray *)items
               cellIdentifier:(NSString *)cellIdentifier;

- (instancetype)initWithItems:(NSArray *)items
               cellIdentifier:(NSString *)cellIdentifier
           configureCellBlock:(HPArrayDataSourceConfigureCellBlock)configureCellBlock;

@property (nonatomic, copy) NSString *cellIdentifier;

@property (nonatomic, copy) HPArrayDataSourceConfigureCellBlock configureCellBlock;

@property (nonatomic, copy) NSArray *items;

@property (nonatomic, weak) IBOutlet id<HPArrayDataSourceDelegate> delegate;

- (NSUInteger)indexOfItem:(id)item;

- (void)removeItemAtIndex:(NSUInteger)index;

@end

@protocol HPArrayDataSourceDelegate <NSObject>

@optional

- (void)dataSource:(HPArrayDataSource*)dataSource configureCell:(id)cell withItem:(id)item atIndex:(NSUInteger)index;

- (void)dataSource:(HPArrayDataSource*)dataSource willMoveItemAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex;

- (void)dataSource:(HPArrayDataSource*)dataSource didMoveItemAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex;

@end
