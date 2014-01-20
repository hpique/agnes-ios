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

@interface HPNote : NSManagedObject

@property (nonatomic, retain) NSNumber * cd_archived;
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
@property (nonatomic, readonly) NSArray *tags;

- (void)setOrder:(NSInteger)order inTag:(NSString*)tag;

- (NSInteger)orderInTag:(NSString*)tag;

+ (NSString *)entityName;

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context;

+ (NSRegularExpression*)tagRegularExpression;

+ (NSString*)textOfBlankNoteWithTag:(NSString*)tag;

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
@property (nonatomic, assign) NSInteger views;
@property (nonatomic, assign) NSInteger inboxOrder;

@end
