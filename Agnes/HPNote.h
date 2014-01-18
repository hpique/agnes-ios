//
//  HPNote.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPNote : NSObject

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSDate *modifiedAt;
@property (nonatomic, copy) NSDate *createdAt;
@property (nonatomic, assign) NSInteger views;
@property (nonatomic, assign) NSInteger order;
@property (nonatomic, assign) BOOL archived;

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BOOL empty;
@property (nonatomic, readonly) NSString *body;
@property (nonatomic, readonly) NSString *modifiedAtDescription;

+ (HPNote*)note;

+ (HPNote*)noteWithText:(NSString*)text;

+ (NSRegularExpression*)tagRegularExpression;

@end
