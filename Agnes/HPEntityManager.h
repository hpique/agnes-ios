//
//  HPEntityManager.h
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface HPEntityManager : NSObject

@property (nonatomic, readonly) NSManagedObjectContext *context;

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context;

#pragma mark Fetching objects

- (NSUInteger)countWithPredicate:(NSPredicate*)predicate;

@property (nonatomic, readonly) NSArray *objects;

- (NSArray*)objectsWithPredicate:(NSPredicate*)predicate;

- (void)save;

- (void)performModelUpdateWithName:(NSString*)actionName save:(BOOL)save block:(void (^)())block;

- (void)performNoUndoModelUpdateAndSave:(BOOL)save block:(void (^)())block;

- (void)removeDuplicatesWithUniquePropertyNamed:(NSString*)propertyName removeBlock:(void (^)(id uniqueValue))removeBlock;

@end

@interface HPEntityManager (Subclassing)

- (NSString*)entityName;

- (void)didInsertObject:(id)object;

- (void)didUpdateObject:(id)object;

- (void)didDeleteObject:(id)object;

- (void)didRefreshObject:(id)object;

- (void)didInvalidateObject:(id)object;

@end

extern NSString* const HPEntityManagerObjectsDidChangeNotification;

@interface NSNotification(HPEntityManager)

/** Returns inserted, deleted, updated, invalidated and refreshed objects of a HPEntityManagerObjectsDidChangeNotification. **/
- (NSSet*)hp_changedObjects;

- (BOOL)hp_invalidatedAllObjects;

@end
