//
//  AGNAppDelegate.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNAppDelegate.h"
#import "HPIndexItem.h"
#import "HPPreferencesManager.h"
#import "AGNRootViewController.h"
#import "HPNoteImporter.h"
#import "HPAgnesNavigationController.h"
#import "HPModelManager.h"
#import "HPTracker.h"
#import "CVRAlertView.h"
#import <iRate/iRate.h>
#import <CoreData/CoreData.h>
#import "TestFlight.h"
#import <Crashlytics/Crashlytics.h>

@interface AGNAppDelegate()<HPModelManagerDelegate, iRateDelegate>

@end

@implementation AGNAppDelegate {
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
    {
        [iRate sharedInstance].verboseLogging = NO;
        [iRate sharedInstance].promptAtLaunch = NO;
        [iRate sharedInstance].daysUntilPrompt = 3;
        [iRate sharedInstance].eventsUntilPrompt = 5;
        [iRate sharedInstance].delegate = self;
        [iRate sharedInstance].cancelButtonLabel = NSLocalizedString(@"Never Show Again", @"");
    }
    
#if DEBUG
    static NSString *const TrackingId = @"UA-48194515-1";
#else
    static NSString *const TrackingId = @"UA-48194515-3";
#endif
    [[HPTracker defaultTracker] setTrackingId:TrackingId];
    
#if !DEBUG
    [Crashlytics startWithAPIKey:@"303898f46fabee8132e6fe426e5cd0045ca8cce2"]; // Must be last
#endif
    {
        _modelManager = [[HPModelManager alloc] init];
        _modelManager.delegate = self;
        [_modelManager setupManagedObjectContext];
        [_modelManager addTutorialIfNeeded];
        [_modelManager saveContext];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReplaceModelNotification:) name:HPModelManagerDidReplaceModelNotification object:_modelManager];
    }
    
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    [preferences styleStatusBar];
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
    AGNRootViewController *drawerController = [[AGNRootViewController alloc] init];
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

#pragma mark iRateDelegate

- (void)iRateDidPromptForRating
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"system" action:@"alert_rate"];
}

- (void)iRateUserDidAttemptToRateApp
{
    NSString *label = [iRate sharedInstance].rateButtonLabel;
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"alert_rate_yes" label:label];
}

- (void)iRateUserDidDeclineToRateApp
{
    NSString *label = [iRate sharedInstance].cancelButtonLabel;
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"alert_rate_no" label:label];
}

- (void)iRateUserDidRequestReminderToRateApp
{
    NSString *label = [iRate sharedInstance].remindButtonLabel;
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"alert_rate_remind" label:label];
}

@end
