//
//  HPNote.h
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HPTag;
@class HPAttachment;

extern NSString* const HPNoteAttachmentAttributeName;

typedef NS_ENUM(NSInteger, HPNoteDetailMode)
{
    HPNoteDetailModeNone,
    HPNoteDetailModeModifiedAt,
    HPNoteDetailModeCharacters,
    HPNoteDetailModeWords,
    HPNoteDetailModeViews,
};
extern const NSInteger HPNoteDetailModeCount;

@interface HPNote : NSManagedObject

@property (nonatomic, retain) NSOrderedSet *attachments;
@property (nonatomic, retain) NSNumber * cd_archived;
@property (nonatomic, retain) NSNumber * cd_detailMode;
@property (nonatomic, retain) NSNumber * cd_views;
@property (nonatomic, retain) NSNumber * cd_inboxOrder;
@property (nonatomic, retain) NSSet *cd_tags;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * modifiedAt;
@property (nonatomic, retain) NSDictionary *tagOrder;
@property (nonatomic, retain) NSString * text;

@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) BOOL empty;
@property (nonatomic, readonly) NSString *body;
@property (nonatomic, readonly) NSString *modifiedAtDescription;
@property (nonatomic, readonly) NSString *modifiedAtLongDescription;
@property (nonatomic, readonly) NSArray *tags;
@property (nonatomic, readonly) BOOL isNew;

- (NSString*)bodyForTagWithName:(NSString*)tagName;

- (void)setOrder:(NSInteger)order inTag:(NSString*)tag;

- (NSInteger)orderInTag:(NSString*)tag;

+ (NSString *)entityName;

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context;

+ (NSRegularExpression*)tagRegularExpression;

+ (NSString*)textOfBlankNoteWithTagOfName:(NSString*)tag;

@end

@interface HPNote (Attachments)

- (void)addAttachment:(HPAttachment*)attachment atIndex:(NSUInteger)index;

- (NSAttributedString*)attributedTextForWidth:(CGFloat)width;

//- (HPAttachment*)attachmentAtCharacterIndex:(NSUInteger)characterIndex;

+ (NSString*)attachmentString;

- (void)replaceAttachments:(NSOrderedSet*)attachments;

@end

@interface HPNote (CoreDataGeneratedAccessors)

- (void)addCd_tagsObject:(HPTag *)value;
- (void)removeCd_tagsObject:(HPTag *)value;
- (void)addCd_tags:(NSSet *)values;
- (void)removeCd_tags:(NSSet *)values;

//- (void)insertObject:(HPAttachment *)value inAttachmentsAtIndex:(NSUInteger)idx;
//- (void)removeObjectFromAttachmentsAtIndex:(NSUInteger)idx;
//- (void)insertAttachments:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
//- (void)removeAttachmentsAtIndexes:(NSIndexSet *)indexes;
//- (void)replaceObjectInAttachmentsAtIndex:(NSUInteger)idx withObject:(HPAttachment *)value;
//- (void)replaceAttachmentsAtIndexes:(NSIndexSet *)indexes withAttachments:(NSArray *)values;
//- (void)addAttachmentsObject:(HPAttachment *)value;
//- (void)removeAttachmentsObject:(HPAttachment *)value;
//- (void)removeAttachments:(NSOrderedSet *)values;

@end

/** See: http://stackoverflow.com/questions/7385439/exception-thrown-in-nsorderedset-generated-accessors
 */
@interface HPNote (CoreDataWorkaroundAccessors)

- (void)hp_addAttachments:(NSOrderedSet *)values;
- (void)hp_addAttachmentsObject:(HPAttachment *)value;
- (void)hp_insertObject:(HPAttachment *)value inAttachmentsAtIndex:(NSUInteger)idx;
- (void)hp_removeAttachments:(NSOrderedSet *)values;

@end

@interface HPNote (CoreDataGeneratedPrimitiveAccessors)

- (void)setPrimitiveText:(NSString *)value;

@end

@interface HPNote (Transient)

@property (nonatomic, assign) BOOL archived;
@property (nonatomic, assign) NSInteger detailMode;
@property (nonatomic, assign) NSInteger views;
@property (nonatomic, assign) NSInteger inboxOrder;

@end
