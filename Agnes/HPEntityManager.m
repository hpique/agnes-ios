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

- (void)didInsertObject:(id)object {}

- (void)didUpdateObject:(id)object {}

- (void)didDeleteObject:(id)object {}

- (NSString*)entityName
{
    @throw NSInternalInconsistencyException;
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
    BOOL found = NO;
    NSString *entityName = [self entityName];
    
    {
        NSSet *insertedObjects = [userInfo objectForKey:NSInsertedObjectsKey];
        for (NSManagedObject *object in insertedObjects)
        {
            if ([object.entity.name isEqualToString:entityName])
            {
                found = YES;
                [self didInsertObject:object];
            }
        }
    }
    
    {
        NSSet *updatedObjects = [userInfo objectForKey:NSUpdatedObjectsKey];
        for (NSManagedObject *object in updatedObjects)
        {
            if ([object.entity.name isEqualToString:entityName])
            {
                found = YES;
                [self didUpdateObject:object];
            }
        }
    }
    
    {
        NSSet *deletedObjects = [userInfo objectForKey:NSDeletedObjectsKey];
        for (NSManagedObject *object in deletedObjects)
        {
            if ([object.entity.name isEqualToString:entityName])
            {
                found = YES;
                [self didDeleteObject:object];
            }
        }
    }
    
    if (found)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:HPEntityManagerObjectsDidChangeNotification object:self];
    }
}


@end
