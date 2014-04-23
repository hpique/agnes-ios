//
//  AGNModelManager.h
//  Agnes
//
//  Created by Hermes on 05/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

@protocol AGNModelManagerDelegate;

extern NSString *const AGNModelManagerWillReplaceModelNotification;
extern NSString *const AGNModelManagerDidReplaceModelNotification;

@interface AGNModelManager : NSObject

@property (nonatomic, weak) id<AGNModelManagerDelegate> delegate;

@property (nonatomic,strong,readonly) NSManagedObjectContext *managedObjectContext;

- (id)init;

- (void)setupManagedObjectContext;

- (void)addTutorialIfNeeded;

- (void)saveContext;

- (void)removeStore;

@end

@protocol AGNModelManagerDelegate <NSObject>

- (void)modelManager:(AGNModelManager*)modelManager confirmCloudStoreImportWithBlock:(void(^)(BOOL confirmed))confirmBlock;

@end