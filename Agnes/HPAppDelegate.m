//
//  HPAppDelegate.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAppDelegate.h"
#import "HPIndexItem.h"
#import "HPPreferencesManager.h"
#import "HPRootViewController.h"
#import "HPNoteImporter.h"
#import "HPAgnesNavigationController.h"
#import "HPAgnesCoreDataStack.h"
#import <CoreData/CoreData.h>
#import "TestFlight.h"
#import "HPTracker.h"

@implementation HPAppDelegate {
    HPAgnesCoreDataStack *_coreDataStack;
}

@synthesize managedObjectContext = _managedObjectContext;


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPAgnesCoreDataStackStoresDidChangeNotification object:_coreDataStack];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{   
    [TestFlight takeOff:@"21242682-ac9b-48b1-a8d6-a3ba293c3135"];
    [[HPTracker defaultTracker] setTrackingId:@"UA-48194515-1"];
    
    {
        _coreDataStack = [[HPAgnesCoreDataStack alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(storesDidChangeNotification:) name:HPAgnesCoreDataStackStoresDidChangeNotification object:_coreDataStack];
    }
    
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    
    NSInteger sessionCount = [preferences increaseSessionCount];
    if (sessionCount == 1)
    {
        [[HPNoteManager sharedManager] addTutorialNotes];
    }
        
    [UIApplication sharedApplication].statusBarHidden = preferences.statusBarHidden;
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    [UIApplication sharedApplication].keyWindow.tintColor = preferences.tintColor;
    [preferences styleNavigationBar:[UINavigationBar appearance]];
    
    application.applicationSupportsShakeToEdit = YES;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.tintColor = preferences.tintColor;
    
    [self.managedObjectContext save:nil];
    [self loadRootViewController];
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

#pragma mark - Private

- (void)loadRootViewController
{
    HPRootViewController *drawerController = [[HPRootViewController alloc] init];
    self.window.rootViewController = drawerController;
}

#pragma mark - Notifications

- (void)storesDidChangeNotification:(NSNotification*)notification
{
    if (self.window.rootViewController)
    {
       // [self loadRootViewController];
    }
}

@end
