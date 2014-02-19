//
//  HPModelManager.m
//  Agnes
//
//  Created by Hermes on 05/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPModelManager.h"
#import "HPNoteManager.h"
#import "HPTagManager.h"
#import "HPPreferencesManager.h"

NSString *const HPModelManagerWillReplaceModelNotification = @"HPModelManagerWillReplaceModelNotification";
NSString *const HPModelManagerDidReplaceModelNotification = @"HPModelManagerDidReplaceModelNotification";

@interface HPModelManager()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSURL *modelURL;
@property (nonatomic, strong) NSURL *storeURL;

@end

@implementation HPModelManager {
    NSManagedObjectModel *_managedObjectModel;
    NSInteger _noteCountBeforeStoreChange;
}

- (id)init
{
    if (self = [super init])
    {
        _storeURL = [[self applicationHiddenDocumentsDirectory] URLByAppendingPathComponent:@"Agnes.sqlite"];
        _modelURL = [[NSBundle mainBundle] URLForResource:@"Agnes" withExtension:@"momd"];
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
    NSPersistentStore *persistentStore = [self.managedObjectContext.persistentStoreCoordinator
                                          addPersistentStoreWithType:NSSQLiteStoreType
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
    NSLog(@"%s\n%@", __PRETTY_FUNCTION__, notification);
    NSManagedObjectContext *moc = self.managedObjectContext;
    [moc performBlockAndWait:^{
        [moc mergeChangesFromContextDidSaveNotification:notification];
    }];
}

- (void)storesWillChange:(NSNotification *)notification
{
    NSLog(@"%s\n%@", __PRETTY_FUNCTION__, notification);
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:HPModelManagerWillReplaceModelNotification object:self];
    });
    NSManagedObjectContext *moc = self.managedObjectContext;
    [moc performBlockAndWait:^{
        NSError *error = nil;
        [[HPNoteManager sharedManager] removeLocalTutorialNotes];
        if ([moc hasChanges])
        {
            [moc save:&error];
        }
        [moc reset];
    }];
}

- (void)storesDidChange:(NSNotification *)notification
{
    NSLog(@"%s\n%@", __PRETTY_FUNCTION__, notification);
    NSDictionary *userInfo = notification.userInfo;
    NSPersistentStoreUbiquitousTransitionType transitionType = [[userInfo objectForKey:NSPersistentStoreUbiquitousTransitionTypeKey] integerValue];
    if (transitionType == NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted)
    {
        [self.managedObjectContext performBlockAndWait:^{
            [[HPTagManager sharedManager] removeDuplicates];
        }];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:HPModelManagerDidReplaceModelNotification object:self];
    });
}

@end
