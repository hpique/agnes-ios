//
//  HPAppDelegate.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAppDelegate.h"
#import "HPNoteListViewController.h"
#import "HPIndexViewController.h"
#import "HPIndexItem.h"
#import "HPPreferencesManager.h"
#import "HPRootViewController.h"
#import "HPNoteImporter.h"
#import "HPAgnesNavigationController.h"
#import <CoreData/CoreData.h>
#import "TestFlight.h"

@implementation HPAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [TestFlight takeOff:@"21242682-ac9b-48b1-a8d6-a3ba293c3135"];
    
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    
    NSInteger sessionCount = [preferences increaseSessionCount];
    if (sessionCount == 1)
    {
        [[HPNoteManager sharedManager] addTutorialNotes];
    }
    
    [UIApplication sharedApplication].statusBarHidden = preferences.statusBarHidden;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [UINavigationBar appearance].barTintColor = preferences.barTintColor;
    [UINavigationBar appearance].tintColor = [UIColor whiteColor];
    [UINavigationBar appearance].titleTextAttributes = @{ NSForegroundColorAttributeName : [UIColor whiteColor]};
    
    application.applicationSupportsShakeToEdit = YES;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.tintColor = preferences.tintColor;
    
    [self.managedObjectContext save:nil];
    
    UINavigationController *centerController = [HPNoteListViewController controllerWithIndexItem:[HPIndexItem inboxIndexItem]];
    HPIndexViewController *indexViewController = [[HPIndexViewController alloc] init];
    HPAgnesNavigationController *leftNavigationController = [[HPAgnesNavigationController alloc] initWithRootViewController:indexViewController];
    HPRootViewController *drawerController = [[HPRootViewController alloc] initWithCenterViewController:centerController leftDrawerViewController:leftNavigationController];
    centerController.delegate = drawerController;
    self.window.rootViewController = drawerController;
    [self.window makeKeyAndVisible];
    
    [[HPNoteImporter sharedImporter] startWatching];
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self saveContext];
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

#pragma mark - Core Data stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext)
    {
        NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
        if (coordinator)
        {
            _managedObjectContext = [[NSManagedObjectContext alloc] init];
            _managedObjectContext.persistentStoreCoordinator = coordinator;
        }
        _managedObjectContext.undoManager = [[NSUndoManager alloc] init];
    }
    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel)
    {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Agnes" withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!_persistentStoreCoordinator)
    {
        
        NSURL *storeURL = [[self applicationHiddenDocumentsDirectory] URLByAppendingPathComponent:@"Agnes.sqlite"];
        
        NSError *error = nil;
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
        {
            /*
             Replace this implementation with code to handle the error appropriately.
             
             abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             
             Typical reasons for an error here include:
             * The persistent store is not accessible;
             * The schema for the persistent store is incompatible with current managed object model.
             Check the error message to determine what the actual problem was.
             
             
             If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
             
             If you encounter schema incompatibility errors during development, you can reduce their frequency by:
             * Simply deleting the existing store:
             [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
             
             * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
             @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
             
             Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
             
             */
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
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

@end
