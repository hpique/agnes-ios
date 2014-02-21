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
#import "HPAttachment.h"
#import "HPData.h"
#import "HPNote.h"
#import "HPModelContextImporter.h"
#import "NSNotification+hp_status.h"

NSString *const HPModelManagerUbiquityIdentityTokenKey = @"HPModelManagerUbiquityIdentityToken";
NSString *const HPModelManagerPersistentStoreURLKey = @"HPModelManagerPersistentStoreURL";
NSString *const HPPersitentStoreMetadataHasTutorialKey = @"HPHasTutorial";

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

- (void)importTutorialIfNeeded
{
    NSPersistentStoreCoordinator *coordinator = _managedObjectContext.persistentStoreCoordinator;
    NSPersistentStore *store = [coordinator.persistentStores firstObject]; // TODO: Maybe keep a reference to the store instead?
    NSDictionary *metadata = store.metadata;
    const BOOL hasTutorial = [metadata[HPPersitentStoreMetadataHasTutorialKey] boolValue];
    if (hasTutorial) return;
    
    [[HPNoteManager sharedManager] addTutorialNotes];
    NSMutableDictionary *modifiedMetadata = metadata.mutableCopy;
    modifiedMetadata[HPPersitentStoreMetadataHasTutorialKey] = @(YES);
    store.metadata = modifiedMetadata;
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

- (NSURL*)copyPersistentStoreAtURL:(NSURL*)storeURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *originPath = storeURL.path;
    if (![fileManager fileExistsAtPath:originPath]) return nil;
    
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    NSString *destinationPath = [cachesDirectory stringByAppendingPathComponent:bundleIdentifier];
    destinationPath = [destinationPath stringByAppendingPathComponent:@"CoreDataImport"];
    NSError *error = nil;
    BOOL result = [fileManager createDirectoryAtPath:destinationPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!result)
    {
        NSLog(@"Failed to create directory with error %@", error);
        return nil;
    }
    NSString *filename = originPath.lastPathComponent;
    destinationPath = [destinationPath stringByAppendingPathComponent:filename];
    [fileManager removeItemAtPath:destinationPath error:nil];
    result = [fileManager copyItemAtPath:originPath toPath:destinationPath error:&error];
    if (!result)
    {
        NSLog(@"Failed to create directory with error %@", error);
        return nil;
    }
    NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
    return destinationURL;
}

- (void)postStatus:(NSString*)message transient:(BOOL)transient
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] hp_postStatus:message transient:transient object:self];
    });
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

- (void)importPersistentStoreAtURL:(NSURL*)importPersistentStoreURL isLocal:(BOOL)isLocal intoPersistentStore:(NSPersistentStore*)persistentStore
{
    if (!isLocal)
    { // Create a copy because we can't add an ubiquity store as a local store without removing the ubiquitous metadata first,
        // and we don't want to modify the original ubiquity store.
        importPersistentStoreURL = [self copyPersistentStoreAtURL:importPersistentStoreURL];
    }
    if (!importPersistentStoreURL) return;
    
    NSManagedObjectContext *importContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    importContext.persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    NSError* error;
    NSPersistentStore *importStore = [importContext.persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                                            configuration:nil
                                                                                                      URL:importPersistentStoreURL
                                                                                                  options:@{NSPersistentStoreRemoveUbiquitousMetadataOption : @(YES)}
                                                                                                    error:&error];
    if (!importStore)
    {
        NSLog(@"Failed to load store with error %@, %@", error, [error userInfo]);
        return;
    }
    if (isLocal)
    {
        [self postStatus:NSLocalizedString(@"Connected to iCloud", @"") transient:YES];
        [self importNotesFromContext:importContext completion:^{}];
    }
    else
    {
        [self.delegate modelManager:self confirmCloudStoreImportWithBlock:^(BOOL confirmed) {
            if (confirmed)
            {
                [self postStatus:NSLocalizedString(@"Importing iCloud notes", @"") transient:NO];
                [self importNotesFromContext:importContext completion:^{
                    [self postStatus:NSLocalizedString(@"Notes imported", @"") transient:YES];
                }];
            }
            [self removeTempStoreAtURL:importPersistentStoreURL];
        }];
        
    }
}

- (void)importNotesFromContext:(NSManagedObjectContext*)fromContext completion:(void(^)())completionBlock
{
    HPModelContextImporter *importer = [[HPModelContextImporter alloc] init];
    [importer importNotesAtContext:fromContext intoContext:_managedObjectContext completion:completionBlock];
}

- (void)removeTempStoreAtURL:(NSURL*)fileURL
{
    NSError* error;
    BOOL result = [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];
    if (!result)
    {
        NSLog(@"Failed to remove temp persistent store with error %@", error);
    }
}

#pragma mark - Notifications

- (void)persistentStoreDidImportUbiquitousContentChanges:(NSNotification*)notification
{ // Careful: This is not always called from the main queue
//    NSLog(@"%s\n%@", __PRETTY_FUNCTION__, notification);
    NSManagedObjectContext *moc = self.managedObjectContext;
    [moc performBlockAndWait:^{
        [moc mergeChangesFromContextDidSaveNotification:notification];
    }];
}

- (void)storesWillChange:(NSNotification *)notification
{ // Careful: This is not always called from the main queue
//    NSLog(@"%s\n%@", __PRETTY_FUNCTION__, notification);
    dispatch_sync(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:HPModelManagerWillReplaceModelNotification object:self];
    });
    NSDictionary *userInfo = notification.userInfo;
    NSManagedObjectContext *moc = self.managedObjectContext;
    NSPersistentStoreUbiquitousTransitionType transitionType = [userInfo[NSPersistentStoreUbiquitousTransitionTypeKey] integerValue];
    if (transitionType == NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted)
    {
        [moc performBlockAndWait:^{
            [[HPNoteManager sharedManager] removeLocalTutorialNotes];
        }];
    }
    [moc performBlockAndWait:^{
        NSError *error = nil;
        if ([moc hasChanges])
        {
            [moc save:&error];
        }
        [moc reset];
    }];
}

- (void)storesDidChange:(NSNotification *)notification
{ // Careful: This is not always called from the main queue
//    NSLog(@"%s\n%@", __PRETTY_FUNCTION__, notification);
    NSDictionary *userInfo = notification.userInfo;
    NSPersistentStoreUbiquitousTransitionType transitionType = [[userInfo objectForKey:NSPersistentStoreUbiquitousTransitionTypeKey] integerValue];
    NSPersistentStore *persistentStore = [userInfo[NSAddedPersistentStoresKey] firstObject];
    id<NSCoding> ubiquityIdentityToken = [NSFileManager defaultManager].ubiquityIdentityToken;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (transitionType == NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted)
    {
        [self.managedObjectContext performBlockAndWait:^{
            [[HPTagManager sharedManager] removeDuplicates];
        }];
    }
    else
    {
        NSData *previousArchivedUbiquityIdentityToken = [defaults objectForKey:HPModelManagerUbiquityIdentityTokenKey];
        if (previousArchivedUbiquityIdentityToken)
        { // Was using ubiquity store
            if (!ubiquityIdentityToken)
            { // Changed to local account
                NSString *urlString = [defaults objectForKey:HPModelManagerPersistentStoreURLKey];
                NSURL *previousPersistentStoreURL = [NSURL URLWithString:urlString];
                [self importPersistentStoreAtURL:previousPersistentStoreURL isLocal:NO intoPersistentStore:persistentStore];
            }
        }
        else
        { // Was using local account
            if (ubiquityIdentityToken)
            { // Changed to ubiquity store
                NSString *urlString = [defaults objectForKey:HPModelManagerPersistentStoreURLKey];
                if (urlString)
                {
                    NSURL *previousPersistentStoreURL = [NSURL URLWithString:urlString];
                    [self importPersistentStoreAtURL:previousPersistentStoreURL isLocal:YES intoPersistentStore:persistentStore];
                }
            }
        }
    }
    if (ubiquityIdentityToken)
    {
        NSData *archivedUbiquityIdentityToken = [NSKeyedArchiver archivedDataWithRootObject:ubiquityIdentityToken];
        [defaults setObject:archivedUbiquityIdentityToken forKey:HPModelManagerUbiquityIdentityTokenKey];
    }
    else
    {
        [defaults removeObjectForKey:HPModelManagerUbiquityIdentityTokenKey];
    }
    NSString *urlString = persistentStore.URL.absoluteString;
    [defaults setObject:urlString forKey:HPModelManagerPersistentStoreURLKey];
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:HPModelManagerDidReplaceModelNotification object:self];
    });
}

@end
