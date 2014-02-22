//
//  HPModelManager.h
//  Agnes
//
//  Created by Hermes on 05/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

@protocol HPModelManagerDelegate;

extern NSString *const HPModelManagerWillReplaceModelNotification;
extern NSString *const HPModelManagerDidReplaceModelNotification;

@interface HPModelManager : NSObject

@property (nonatomic, weak) id<HPModelManagerDelegate> delegate;

@property (nonatomic,strong,readonly) NSManagedObjectContext *managedObjectContext;

- (id)init;

- (void)setupManagedObjectContext;

- (void)importTutorialIfNeeded;

- (void)saveContext;

@end

@protocol HPModelManagerDelegate <NSObject>

- (void)modelManager:(HPModelManager*)modelManager confirmCloudStoreImportWithBlock:(void(^)(BOOL confirmed))confirmBlock;

@end