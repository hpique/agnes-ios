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

@property (nonatomic, retain) NSNumber * cd_archived;
@property (nonatomic, retain) NSSet *cd_attachments; // iCloud doesn't support ordered relationships
@property (nonatomic, retain) NSNumber * cd_detailMode;
@property (nonatomic, retain) NSNumber * cd_views;
@property (nonatomic, retain) NSSet *cd_tags;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSDate * modifiedAt;
@property (nonatomic, retain) NSDictionary *tagOrder;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * uuid;

@property (nonatomic, readonly) BOOL empty;
@property (nonatomic, readonly) NSString *firstTagName;
@property (nonatomic, readonly) NSArray *tagNames;
@property (nonatomic, readonly) BOOL isNew;

- (void)setOrder:(CGFloat)order inTag:(NSString*)tag;

- (CGFloat)orderInTag:(NSString*)tag;

+ (NSString *)entityName;

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context;

+ (NSRegularExpression*)tagRegularExpression;

@end

@interface HPNote (Attachments)

- (NSUInteger)addAttachment:(HPAttachment*)attachment atIndex:(NSUInteger)index;

+ (NSString*)attachmentString;

- (void)replaceAttachments:(NSArray*)attachments;

@property (nonatomic, readonly) NSArray *attachments;

@end

@interface HPNote (View)

@property (nonatomic, readonly) NSString *body;
@property (nonatomic, readonly) NSString *modifiedAtDescription;
@property (nonatomic, readonly) NSString *modifiedAtLongDescription;
@property (nonatomic, readonly) NSString *summary;
@property (nonatomic, readonly) NSString *title;

@end

@interface HPNote (CoreDataGeneratedAccessors)

- (void)addCd_tagsObject:(HPTag *)value;
- (void)removeCd_tagsObject:(HPTag *)value;
- (void)addCd_tags:(NSSet *)values;
- (void)removeCd_tags:(NSSet *)values;

@end

@interface HPNote (CoreDataGeneratedPrimitiveAccessors)

- (void)setPrimitiveText:(NSString *)value;

@end

@interface HPNote (Transient)

@property (nonatomic, assign) BOOL archived;
@property (nonatomic, assign) NSInteger detailMode;
@property (nonatomic, assign) NSInteger views;

@end
