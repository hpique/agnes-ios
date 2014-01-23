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

@interface HPTag : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet *cd_notes;
@property (nonatomic, retain) NSNumber *cd_order;

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

@property (nonatomic, assign) NSInteger order;

@end
