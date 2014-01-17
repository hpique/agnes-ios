//
//  HPNoteManager.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HPNote;

@interface HPNoteManager : NSObject

@property (nonatomic, readonly) NSArray *notes;

- (void)addNote:(HPNote*)note;
- (void)removeNote:(HPNote*)note;

+ (HPNoteManager*)sharedManager;

@end
