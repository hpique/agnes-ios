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

@property (nonatomic, readonly) NSArray *inboxResults;
@property (nonatomic, readonly) NSArray *archivedResults;

- (NSArray*)search:(NSString*)search inIndexItem:(HPIndexItem*)indexItem;

@end
