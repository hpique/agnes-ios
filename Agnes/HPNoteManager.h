//
//  HPNoteManager.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPEntityManager.h"
#import "HPNote.h"
#import "HPTag.h"

@interface HPNoteManager : HPEntityManager

@property (nonatomic, readonly) NSArray *systemNotes;

- (void)addTutorialNotes;

+ (HPNoteManager*)sharedManager;

+ (NSArray*)sortedNotes:(NSArray*)notes mode:(HPTagSortMode)mode tag:(HPTag*)tag;

@end

@interface HPNoteManager(Actions)

- (void)archiveNote:(HPNote*)note;

- (void)attachToNote:(HPNote*)note image:(UIImage*)image index:(NSInteger)index;

- (HPNote*)blankNoteWithTagOfName:(NSString*)tag;

- (void)editNote:(HPNote*)note text:(NSString*)text;

- (void)importNoteWithText:(NSString*)text createdAt:(NSDate*)createdAt modifiedAt:(NSDate*)modifiedAt;

- (void)reorderNotes:(NSArray*)notes tagName:(NSString*)tagName;

- (void)setDetailMode:(HPNoteDetailMode)detailMode ofNote:(HPNote*)note;

- (void)trashNote:(HPNote*)note;

- (void)unarchiveNote:(HPNote*)note;

- (void)viewNote:(HPNote*)note;

@end
