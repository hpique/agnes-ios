//
//  HPEntityManager.h
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const HPEntityManagerObjectsDidChangeNotification;

@interface HPEntityManager : NSObject

@property (nonatomic, readonly) NSManagedObjectContext *context;
@property (nonatomic, readonly) NSArray *objects;

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context;

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
