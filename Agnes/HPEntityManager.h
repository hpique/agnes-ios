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

- (void)performModelUpdateBlock:(void (^)())block actionName:(NSString*)actionName;

- (void)performNoUndoModelUpdateBlock:(void (^)())block;

@end

@interface HPEntityManager (Subclassing)

- (NSString*)entityName;

- (void)didInsertObject:(id)object;

- (void)didUpdateObject:(id)object;

- (void)didDeleteObject:(id)object;

@end
