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
#import "MMDrawerController.h"

@implementation HPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    UIViewController *centerController = [HPNoteListViewController controllerWithIndexItem:[HPIndexItem allNotesIndexItem]];
    HPIndexViewController *indexViewController = [[HPIndexViewController alloc] init];
    UINavigationController *leftNavigationController = [[UINavigationController alloc] initWithRootViewController:indexViewController];
    MMDrawerController *drawerController = [[MMDrawerController alloc] initWithCenterViewController:centerController leftDrawerViewController:leftNavigationController];

    self.window.rootViewController = drawerController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
