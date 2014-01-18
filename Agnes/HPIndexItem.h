//
//  HPIndexItem.h
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPIndexItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, readonly) NSArray *notes;

+ (HPIndexItem*)inboxIndexItem;

+ (HPIndexItem*)archiveIndexItem;

+ (HPIndexItem*)indexItemWithTag:(NSString*)tag;

@end

@interface HPIndexItemTag : HPIndexItem

@end

@interface HPIndexItemPredicate : HPIndexItem

@property (nonatomic, strong) NSPredicate *predicate;

@end