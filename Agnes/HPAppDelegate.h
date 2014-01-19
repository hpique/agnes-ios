//
//  HPAppDelegate.h
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HPAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

/** Returns the managed object context for the application. If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

/** Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

/** Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory;

- (void)saveContext;

@end
