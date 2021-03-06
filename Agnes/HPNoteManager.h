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

@interface HPNoteImport : NSObject

@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *modifiedAt;
@property (nonatomic, strong) NSArray *attachments;

+ (HPNoteImport*)noteImportWithText:(NSString*)text createdAt:(NSDate*)createdAt modifiedAt:(NSDate*)modifiedAt attachments:(NSArray*)attachments;

- (HPNote*)insertNoteInContext:(NSManagedObjectContext*)context;

@end

@interface HPNoteManager : HPEntityManager

+ (HPNoteManager*)sharedManager;

#pragma mark Fetching notes

- (HPNote*)noteForUUID:(NSString*)uuid;

#pragma mark Blank notes

- (HPNote*)blankNoteWithTag:(HPTag*)tag;

+ (NSString*)textOfBlankNoteWithTag:(HPTag*)tag;

#pragma mark Tutorial notes

- (void)addTutorialNotesIfNeeded;

- (void)removeTutorialNotes;

#pragma mark System notes

@property (nonatomic, readonly) NSArray *systemNotes;

- (BOOL)isSystemNote:(HPNote*)note;

@end

@interface HPNoteManager(Actions)

- (void)addNoteWithText:(NSString*)text tag:(HPTag*)tag;

- (NSUInteger)attachToNote:(HPNote*)note data:(NSData*)data type:(NSString*)type index:(NSInteger)index;

- (void)editNote:(HPNote*)note text:(NSString*)text attachments:(NSArray*)attachments;

- (void)importNotes:(NSArray*)notes;

- (void)reorderNotes:(NSArray*)notes exchangeObjectAtIndex:(NSUInteger)fromIndex withObjectAtIndex:(NSUInteger)toIndex inTag:(HPTag*)tag;

- (void)setDetailMode:(HPNoteDetailMode)detailMode ofNote:(HPNote*)note;

- (void)trashNote:(HPNote*)note;

- (void)viewNote:(HPNote*)note;

@end
