//
//  HPNote.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPNote : NSObject

@property (nonatomic, copy) NSString *body;
@property (nonatomic, copy) NSDate *modifiedAt;
@property (nonatomic, copy) NSDate *createdAt;
@property (nonatomic, assign) NSInteger views;

@property (nonatomic, readonly) NSString *title;

+ (HPNote*)note;

+ (HPNote*)noteWithBody:(NSString*)body;

@end
