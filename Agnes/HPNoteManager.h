//
//  HPNoteManager.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HPNote;
@class HPNote;

typedef NS_ENUM(NSInteger, HPNoteDisplayCriteria) {
    HPNoteDisplayCriteriaOrder,
    HPNoteDisplayCriteriaModifiedAt,
    HPNoteDisplayCriteriaAlphabetical,
    HPNoteDisplayCriteriaViews,
};

extern NSString* const HPNoteManagerDidUpdateNotesNotification;
extern NSString* const HPNoteManagerDidUpdateTagsNotification;

@interface HPNoteManager : NSObject

@property (nonatomic, readonly) NSArray *notes;
@property (nonatomic, readonly) NSArray *systemNotes;
@property (nonatomic, readonly) NSArray *tags2;

- (NSArray*)notesWithTag:(NSString*)tag;

- (void)removeNote:(HPNote*)note;

+ (HPNoteManager*)sharedManager;

+ (NSArray*)sortedNotes:(NSArray*)notes criteria:(HPNoteDisplayCriteria)criteria tag:(NSString*)tag;

- (NSArray*)tagNamesWithPrefix:(NSString*)prefix;

- (void)save;

- (HPNote*)blankNoteWithTag:(NSString*)tag;

@end

