//
//  HPModelManager.h
//  Agnes
//
//  Created by Hermes on 05/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

extern NSString *const HPModelManagerWillReplaceModelNotification;
extern NSString *const HPModelManagerDidReplaceModelNotification;

@interface HPModelManager : NSObject

- (id)init;

@property (nonatomic,strong,readonly) NSManagedObjectContext *managedObjectContext;

- (void)importTutorialIfNeeded;

- (void)saveContext;

@end
