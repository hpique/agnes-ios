//
//  HPSectionArrayDataSource.h
//  Agnes
//
//  Created by Hermés Piqué on 02/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPDataSource.h"

@protocol HPSectionArrayDataSourceDelegate;

@interface HPSectionArrayDataSource : NSObject<HPDataSource>

- (instancetype)initWithSections:(NSArray *)sections
               cellIdentifier:(NSString *)cellIdentifier;

@property (nonatomic, weak) id<HPSectionArrayDataSourceDelegate> delegate;

@property (nonatomic, readonly) NSArray *sections;

- (NSIndexPath*)indexPathOfItem:(id)item;

@end

@protocol HPSectionArrayDataSourceDelegate <NSObject>

@optional

- (void)dataSource:(HPSectionArrayDataSource*)dataSource configureCell:(id)cell withItem:(id)item atIndexPath:(NSIndexPath*)indexPath;

@end
