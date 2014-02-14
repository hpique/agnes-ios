//
//  HPNoteAction.h
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPNote.h"

@interface HPNoteAction : NSObject

- (void)apply:(HPNote*)note text:(NSMutableAttributedString*)mutableText view:(id)view;

+ (void)willDisplayNote:(HPNote*)note text:(NSMutableAttributedString*)mutableText view:(id)view;

+ (BOOL)willEditNote:(HPNote*)note text:(NSMutableString*)mutableText editor:(UITextView*)textView;

@end

@interface HPNote(Action)

- (BOOL)canAutosave;

- (BOOL)isSystem;

@end
