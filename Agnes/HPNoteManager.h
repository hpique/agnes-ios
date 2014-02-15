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

+ (NSArray*)sortedNotes:(NSArray*)notes mode:(HPTagSortMode)mode tag:(HPTag*)tag;

#pragma mark Tutorial notes

- (void)addTutorialNotes;

- (void)removeTutorialNotes;

#pragma mark System notes

@property (nonatomic, readonly) NSArray *systemNotes;

- (BOOL)isSystemNote:(HPNote*)note;

@end

@interface HPNoteManager(Actions)

- (NSUInteger)attachToNote:(HPNote*)note data:(NSData*)data type:(NSString*)type index:(NSInteger)index;

- (HPNote*)blankNoteWithTagOfName:(NSString*)tag;

- (void)editNote:(HPNote*)note text:(NSString*)text attachments:(NSArray*)attachments;

- (void)importNotes:(NSArray*)notes;

- (void)reorderNotes:(NSArray*)notes tagName:(NSString*)tagName;

- (void)setDetailMode:(HPNoteDetailMode)detailMode ofNote:(HPNote*)note;

- (void)trashNote:(HPNote*)note;

- (void)viewNote:(HPNote*)note;

@end
