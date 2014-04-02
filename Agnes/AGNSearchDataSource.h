//
//  AGNSearchDataSource.h
//  Agnes
//
//  Created by Hermés Piqué on 02/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPSectionArrayDataSource.h"
@class HPIndexItem;

@interface AGNSearchDataSource : HPSectionArrayDataSource

- (instancetype)initWithSearch:(NSString*)search
                     indexItem:(HPIndexItem*)indexItem
                cellIdentifier:(NSString *)cellIdentifier;

@property (nonatomic, readonly) NSArray *inboxResults;
@property (nonatomic, readonly) NSArray *archivedResults;

@end
