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
    NSAssert([_context save:&error], @"Context save failed with error %@", error.localizedDescription);
}

- (void)removeDuplicatesWithUniquePropertyNamed:(NSString*)propertyName removeBlock:(void (^)(id uniqueValue))removeBlock
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    fetchRequest.includesPendingChanges = NO;
    
    NSExpression *countExpr = [NSExpression expressionWithFormat:@"count:(%K)", propertyName];
    NSExpressionDescription *countExprDesc = [[NSExpressionDescription alloc] init];
    static NSString *countKey = @"count";
    countExprDesc.name = countKey;
    countExprDesc.expression = countExpr;
    countExprDesc.expressionResultType = NSInteger64AttributeType;
    
    NSManagedObjectModel *model = self.context.persistentStoreCoordinator.managedObjectModel;
    NSEntityDescription *entity = [[model entitiesByName] objectForKey:[self entityName]];
    NSAttributeDescription *uniqueAttribute = [[entity propertiesByName] objectForKey:propertyName];
    fetchRequest.propertiesToFetch = @[uniqueAttribute, countExprDesc];
    fetchRequest.propertiesToGroupBy = @[uniqueAttribute];
    fetchRequest.resultType = NSDictionaryResultType;
    
    NSError *error = nil;
    NSArray *countDictionaries = [self.context executeFetchRequest:fetchRequest error:&error];
    NSAssert(countDictionaries, @"Fetch %@ failed with error %@", fetchRequest, error);
    for (NSDictionary *dictionary in countDictionaries)
    {
        id uniqueValue = [dictionary objectForKey:uniqueAttribute.name];
        NSInteger count = [[dictionary objectForKey:countKey] integerValue];
        if (count > 1)
        {
            removeBlock(uniqueValue);
        }
    }
}

#pragma mark - Private

- (void)objectsDidChangeNotification:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    id invalidatedAll = [userInfo objectForKey:NSInvalidatedAllObjectsKey];
    if (invalidatedAll)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:HPEntityManagerObjectsDidChangeNotification object:self userInfo:userInfo];
        return;
    }
    
    NSSet *inserted = [self filterUserInfo:userInfo key:NSInsertedObjectsKey selector:@selector(didInsertObject:)];
    NSSet *updated = [self filterUserInfo:userInfo key:NSUpdatedObjectsKey selector:@selector(didUpdateObject:)];
    NSSet *deleted = [self filterUserInfo:userInfo key:NSDeletedObjectsKey selector:@selector(didDeleteObject:)];
    NSSet *refreshed = [self filterUserInfo:userInfo key:NSRefreshedObjectsKey selector:@selector(didRefreshObject:)];
    NSSet *invalidated = [self filterUserInfo:userInfo key:NSInvalidatedObjectsKey selector:@selector(didInvalidateObject:)];
    
    if (inserted.count > 0 || updated.count > 0 || deleted.count > 0 || refreshed.count > 0 || invalidated.count > 0)
    {
        NSDictionary *userInfo = @{NSInsertedObjectsKey : inserted, NSUpdatedObjectsKey : updated, NSDeletedObjectsKey : deleted, NSRefreshedObjectsKey : refreshed, NSInvalidatedObjectsKey : invalidated};
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
    [self.context.undoManager setActionName:actionName];
    block();
    if (save)
    {
        [self save];
    }
    [self.context.undoManager endUndoGrouping];
}

- (void)performNoUndoModelUpdateAndSave:(BOOL)save block:(void (^)())block
{
    [self.context processPendingChanges];
    [self.context.undoManager disableUndoRegistration];
    block();
    if (save)
    {
        [self save];
    }
    [self.context processPendingChanges];
    [self.context.undoManager enableUndoRegistration];
}

@end

@implementation HPEntityManager(Subclassing)

- (void)didInsertObject:(id)object {}

- (void)didUpdateObject:(id)object {}

- (void)didDeleteObject:(id)object {}

- (void)didRefreshObject:(id)object {}

- (void)didInvalidateObject:(id)object {}

- (NSString*)entityName
{
    @throw NSInternalInconsistencyException;
}

@end