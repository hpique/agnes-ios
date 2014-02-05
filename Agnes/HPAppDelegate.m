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
#import "HPAgnesCoreDataStack.h"
#import <CoreData/CoreData.h>
#import "TestFlight.h"

@implementation HPAppDelegate {
    HPAgnesCoreDataStack *_coreDataStack;
}

@synthesize managedObjectContext = _managedObjectContext;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{   
    [TestFlight takeOff:@"21242682-ac9b-48b1-a8d6-a3ba293c3135"];
    
    {
        _coreDataStack = [[HPAgnesCoreDataStack alloc] init];
    }
    
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    
    NSInteger sessionCount = [preferences increaseSessionCount];
    if (sessionCount == 1)
    {
        [[HPNoteManager sharedManager] addTutorialNotes];
    }
        
    [UIApplication sharedApplication].statusBarHidden = preferences.statusBarHidden;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
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
    [_coreDataStack saveContext];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [_coreDataStack saveContext];
}

#pragma mark - Public

- (NSManagedObjectContext*)managedObjectContext
{
    return _coreDataStack.managedObjectContext;
}

@end
