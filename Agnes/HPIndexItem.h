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
@property (nonatomic, strong) NSPredicate *predicate;

+ (HPIndexItem*)indexItemWithTitle:(NSString*)title predictate:(NSPredicate*)predicate;

+ (HPIndexItem*)allNotesIndexItem;

@end
