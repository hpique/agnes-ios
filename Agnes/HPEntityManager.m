//
//  HPEntityManager.m
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPEntityManager.h"
#import <CoreData/CoreData.h>

NSString* const HPEntityManagerObjectsDidChangeNotification = @"HPEntityManagerObjectsDidChangeNotification";

@implementation HPEntityManager

@synthesize context = _context;

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)context
{
    if (self = [super init])
    {
        _context = context;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(objectsDidChangeNotification:) name:NSManagedObjectContextObjectsDidChangeNotification object:_context];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextObjectsDidChangeNotification object:_context];
}

- (NSArray*)objects
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    NSError *error;
    NSArray *objects = [_context executeFetchRequest:fetchRequest error:&error];
    NSAssert(objects, @"Fetch %@ failed with error %@", fetchRequest, error.localizedDescription);
    return objects;
}

- (void)save
{
    NSError *error;
    BOOL result = [_context save:&error];
    NSAssert(result, @"Context save failed with error %@", error.localizedDescription);
}

#pragma mark - Private

- (void)objectsDidChangeNotification:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    NSSet *inserted = [self filterUserInfo:userInfo key:NSInsertedObjectsKey selector:@selector(didInsertObject:)];
    NSSet *updated = [self filterUserInfo:userInfo key:NSUpdatedObjectsKey selector:@selector(didUpdateObject:)];
    NSSet *deleted = [self filterUserInfo:userInfo key:NSDeletedObjectsKey selector:@selector(didDeleteObject:)];
    
    if (inserted.count > 0 || updated.count > 0 || deleted.count > 0)
    {
        NSDictionary *userInfo = @{NSInsertedObjectsKey : inserted, NSUpdatedObjectsKey : updated, NSDeletedObjectsKey : deleted};
        [[NSNotificationCenter defaultCenter] postNotificationName:HPEntityManagerObjectsDidChangeNotification object:self userInfo:userInfo];
    }
}

- (NSSet*)filterUserInfo:(NSDictionary*)userInfo key:(NSString*)key selector:(SEL)selector
{
    NSString *entityName = [self entityName];
    NSMutableSet *filtered = [NSMutableSet set];
    NSSet *changedObjects = [userInfo objectForKey:key];
    for (NSManagedObject *object in changedObjects)
    {
        if ([object.entity.name isEqualToString:entityName])
        {
            [filtered addObject:object];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:selector withObject:object];
#pragma clang diagnostic pop
        }
    }
    return filtered;
}

- (void)performModelUpdateWithName:(NSString*)actionName save:(BOOL)save block:(void (^)())block ;
{
    [self.context.undoManager beginUndoGrouping];
    [self.context.undoManager setActionName:NSLocalizedString(actionName, @"")];
    block();
    if (save)
    {
        [self save];
    }
    [self.context.undoManager endUndoGrouping];
}

- (void)performNoUndoModelUpdateBlock:(void (^)())block
{
    [self.context processPendingChanges];
    [self.context.undoManager disableUndoRegistration];
    block();
    [self.context processPendingChanges];
    [self.context.undoManager enableUndoRegistration];
}

@end

@implementation HPEntityManager(Subclassing)

- (void)didInsertObject:(id)object {}

- (void)didUpdateObject:(id)object {}

- (void)didDeleteObject:(id)object {}

- (NSString*)entityName
{
    @throw NSInternalInconsistencyException;
}

@end