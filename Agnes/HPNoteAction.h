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

- (void)apply:(HPNote*)note editableText:(NSMutableString*)editableText;

+ (NSArray*)preActions;

+ (void)applyPreActions:(HPNote*)note editableText:(NSMutableString*)editableText;

@end
