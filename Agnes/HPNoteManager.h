//
//  HPNoteManager.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HPNote;

typedef NS_ENUM(NSInteger, HPNoteDisplayCriteria) {
    HPNoteDisplayCriteriaAlphabetical,
    HPNoteDisplayCriteriaModifiedAt,
    HPNoteDisplayCriteriaViews,
};

@interface HPNoteManager : NSObject

@property (nonatomic, readonly) NSArray *notes;

- (void)addNote:(HPNote*)note;

- (NSArray*)sortedNotesWithCriteria:(HPNoteDisplayCriteria)criteria;

- (void)removeNote:(HPNote*)note;

+ (HPNoteManager*)sharedManager;

@end
