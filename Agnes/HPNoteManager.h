//
//  HPNoteManager.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPEntityManager.h"
@class HPNote;
@class HPTag;

typedef NS_ENUM(NSInteger, HPNoteDisplayCriteria) {
    HPNoteDisplayCriteriaOrder,
    HPNoteDisplayCriteriaModifiedAt,
    HPNoteDisplayCriteriaAlphabetical,
    HPNoteDisplayCriteriaViews,
};

@interface HPNoteManager : HPEntityManager

@property (nonatomic, readonly) NSArray *systemNotes;

- (void)addTutorialNotes;

- (void)removeNote:(HPNote*)note;

+ (HPNoteManager*)sharedManager;

+ (NSArray*)sortedNotes:(NSArray*)notes criteria:(HPNoteDisplayCriteria)criteria tag:(NSString*)tag;

- (HPNote*)blankNoteWithTag:(NSString*)tag;

@end

