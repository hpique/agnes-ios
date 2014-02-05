//
//  HPAgnesCoreDataStack.m
//  Agnes
//
//  Created by Hermes on 05/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAgnesCoreDataStack.h"


@interface HPAgnesCoreDataStack()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSURL *modelURL;
@property (nonatomic, strong) NSURL *storeURL;

@end

@implementation HPAgnesCoreDataStack {
    NSManagedObjectModel *_managedObjectModel;
}

- (id)init
{
    if (self = [super init])
    {
        _storeURL = [[self applicationHiddenDocumentsDirectory] URLByAppendingPathComponent:@"Agnes.sqlite"];
        _modelURL = [[NSBundle mainBundle] URLForResource:@"Agnes" withExtension:@"momd"];
//        [self removeStore];
        [self setupManagedObjectContext];
    }
    return self;
}

- (void)setupManagedObjectContext
{
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _managedObjectContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
    _managedObjectContext.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    _managedObjectContext.undoManager = [[NSUndoManager alloc] init];
    
    __weak NSPersistentStoreCoordinator *psc = self.managedObjectContext.persistentStoreCoordinator;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(storesWillChange:) name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:psc];
    [notificationCenter addObserver:self selector:@selector(storesDidChange:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:psc];
    [notificationCenter addObserver:self selector:@selector(persistentStoreDidImportUbiquitousContentChanges:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:psc];
    
    NSError* error;
    NSPersistentStore *persistentStore = [self.managedObjectContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                       configuration:nil
                                                                                 URL:self.storeURL
                                                                             options:@{ NSPersistentStoreUbiquitousContentNameKey : @"notes" }
                                                                               error:&error];
    if (!persistentStore)
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (NSManagedObjectModel*)managedObjectModel
{
    if (!_managedObjectModel)
    {
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelURL];
    }
    return _managedObjectModel;
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (!managedObjectContext) return;
    
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
    {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

#pragma mark - Private

- (NSURL *)applicationHiddenDocumentsDirectory
{
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject];
    NSString *path = [libraryPath stringByAppendingPathComponent:@"Private Documents"];
    NSURL *pathURL = [NSURL fileURLWithPath:path];
    
    BOOL isDirectory = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
        if (isDirectory) {
            return pathURL;
        } else {
            // Handle error. ".data" is a file which should not be there...
            [NSException raise:@"'Private Documents' exists, and is a file" format:@"Path: %@", path];
            // NSError *error = nil;
            // if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error]) {
            //     [NSException raise:@"could not remove file" format:@"Path: %@", path];
            // }
        }
    }
    NSError *error = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error])
    {
        [NSException raise:@"Failed creating directory" format:@"[%@], %@", path, error];
    }
    return pathURL;
}

- (void)removeStore
{
    NSError* error;
    BOOL success = [NSPersistentStoreCoordinator
                    removeUbiquitousContentAndPersistentStoreAtURL:_storeURL
                    options:@{ NSPersistentStoreUbiquitousContentNameKey : @"notes" }
                    error:&error];
    if (!success)
    {
        NSLog(@"Failed to remove %@, %@", error, [error userInfo]);
    }
}


#pragma mark - Notifications

- (void)persistentStoreDidImportUbiquitousContentChanges:(NSNotification*)notification
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%@", notification.userInfo.description);
    
    NSManagedObjectContext *moc = self.managedObjectContext;
    [moc performBlock:^{
        [moc mergeChangesFromContextDidSaveNotification:notification];
        
        // you may want to post a notification here so that which ever part of your app
        // needs to can react appropriately to what was merged.
        // An exmaple of how to iterate over what was merged follows, although I wouldn't
        // recommend doing it here. Better handle it in a delegate or use notifications.
        // Note that the notification contains NSManagedObjectIDs
        // and not NSManagedObjects.
        NSDictionary *changes = notification.userInfo;
        NSMutableSet *allChanges = [NSMutableSet new];
        [allChanges unionSet:changes[NSInsertedObjectsKey]];
        [allChanges unionSet:changes[NSUpdatedObjectsKey]];
        [allChanges unionSet:changes[NSDeletedObjectsKey]];
        
        for (NSManagedObjectID *objID in allChanges) {
            // do whatever you need to with the NSManagedObjectID
            // you can retrieve the object from with [moc objectWithID:objID]
        }
        
    }];
}

// Subscribe to NSPersistentStoreCoordinatorStoresWillChangeNotification
// most likely to be called if the user enables / disables iCloud
// (either globally, or just for your app) or if the user changes
// iCloud accounts.
- (void)storesWillChange:(NSNotification *)notification
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%@", notification.userInfo.description);
    
    NSManagedObjectContext *moc = self.managedObjectContext;
    [moc performBlockAndWait:^{
        NSError *error = nil;
        if ([moc hasChanges]) {
            [moc save:&error];
        }
        
        [moc reset];
    }];
    
    // now reset your UI to be prepared for a totally different
    // set of data (eg, popToRootViewControllerAnimated:)
    // but don't load any new data yet.
}

// Subscribe to NSPersistentStoreCoordinatorStoresDidChangeNotification
- (void)storesDidChange:(NSNotification *)notification
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%@", notification.userInfo.description);
    // here is when you can refresh your UI and
    // load new data from the new store
}


@end
