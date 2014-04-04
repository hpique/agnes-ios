//
//  HPTag.h
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
@class HPNote;

typedef NS_ENUM(NSInteger, HPTagSortMode) {
    HPTagSortModeOrder,
    HPTagSortModeModifiedAt,
    HPTagSortModeAlphabetical,
    HPTagSortModeViews,
    HPTagSortModeTag
};

@interface HPTag : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber *cd_isSystem;
@property (nonatomic, retain) NSSet *cd_notes;
@property (nonatomic, retain) NSNumber *cd_order;
@property (nonatomic, strong) NSNumber *cd_sortMode;
@property (nonatomic, strong) NSNumber *cd_views;
@property (nonatomic, strong) NSString *uuid;
@property (nonatomic, strong) NSDate *viewedAt;

@end

@interface HPTag (CoreDataGeneratedAccessors)

- (void)addCd_notesObject:(HPNote *)value;
- (void)removeCd_notesObject:(HPNote *)value;
- (void)addCd_notes:(NSSet *)values;
- (void)removeCd_notes:(NSSet *)values;

@end

@interface HPTag (Convenience)

+ (NSString *)entityName;

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context;

@end

@interface HPTag(Transient)

@property (nonatomic, assign) BOOL isSystem;
@property (nonatomic, assign) CGFloat order;
@property (nonatomic, assign) NSInteger sortMode;
@property (nonatomic, assign) NSUInteger views;

@end
