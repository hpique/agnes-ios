//
//  HPNoteAction.h
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HPNote;

@interface HPNoteAction : NSObject

- (void)apply:(HPNote*)note text:(NSMutableString*)mutableText view:(id)view;

+ (void)willDisplayNote:(HPNote*)note text:(NSMutableString*)mutableText view:(id)view;

+ (void)willEditNote:(HPNote*)note editor:(UITextView*)textView;

@end
