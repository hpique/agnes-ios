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
    HPNoteDisplayCriteriaOrder,
    HPNoteDisplayCriteriaModifiedAt,
    HPNoteDisplayCriteriaAlphabetical,
    HPNoteDisplayCriteriaViews,
};

@interface HPNoteManager : NSObject

@property (nonatomic, readonly) NSArray *notes;
@property (nonatomic, readonly) NSInteger nextOrder;

- (void)addNote:(HPNote*)note;

- (HPNote*)blankNote;

- (void)removeNote:(HPNote*)note;

- (NSArray*)sortedNotesWithCriteria:(HPNoteDisplayCriteria)criteria;

+ (HPNoteManager*)sharedManager;

@end
