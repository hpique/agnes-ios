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
#import "HPModelManager.h"
#import "HPTracker.h"
#import "CVRAlertView.h"
#import <iRate/iRate.h>
#import <CoreData/CoreData.h>
#import "TestFlight.h"

@interface HPAppDelegate()<HPModelManagerDelegate>

@end

@implementation HPAppDelegate {
    HPModelManager *_modelManager;
}

@synthesize managedObjectContext = _managedObjectContext;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPModelManagerDidReplaceModelNotification object:_modelManager];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{   
    [TestFlight takeOff:@"21242682-ac9b-48b1-a8d6-a3ba293c3135"];
    [[HPTracker defaultTracker] setTrackingId:@"UA-48194515-1"];
    [iRate sharedInstance].verboseLogging = NO;

    {
        _modelManager = [[HPModelManager alloc] init];
        _modelManager.delegate = self;
        [_modelManager setupManagedObjectContext];
        [_modelManager importTutorialIfNeeded];
        [_modelManager saveContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReplaceModelNotification:) name:HPModelManagerDidReplaceModelNotification object:_modelManager];
    }
    
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];    
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
    [_modelManager saveContext];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [_modelManager saveContext];
}

#pragma mark - Public

- (NSManagedObjectContext*)managedObjectContext
{
    return _modelManager.managedObjectContext;
}

#pragma mark Private

- (void)loadRootViewController
{
    HPRootViewController *drawerController = [[HPRootViewController alloc] init];
    self.window.rootViewController = drawerController;
}

#pragma mark  Notifications

- (void)didReplaceModelNotification:(NSNotification*)notification
{
    if (self.window.rootViewController)
    {
       [self loadRootViewController];
    }
}

#pragma mark HPModelManagerDelegate

- (void)modelManager:(HPModelManager*)modelManager confirmCloudStoreImportWithBlock:(void(^)(BOOL confirmed))confirmBlock
{
    CVRAlertView *alertView = [[CVRAlertView alloc] init];
    alertView.title = NSLocalizedString(@"iCloud Off", @"");
    alertView.message = NSLocalizedString(@"Would you like keep in your device the previously synced iCloud notes?", @"");
    [alertView addButtonWithTitle:NSLocalizedString(@"Don't Keep", @"")];
    NSUInteger cancelIndex = [alertView addButtonWithTitle:NSLocalizedString(@"Keep", @"")];
    alertView.cancelButtonIndex = cancelIndex;
    [alertView showWithClickBlock:^(NSInteger buttonIndex) {
        BOOL confirmed = buttonIndex == alertView.cancelButtonIndex;
        confirmBlock(confirmed);
    }];
}

@end
