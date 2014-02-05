//
//  HPAgnesCoreDataStack.h
//  Agnes
//
//  Created by Hermes on 05/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
@import CoreData;

@interface HPAgnesCoreDataStack : NSObject

- (id)init;

@property (nonatomic,strong,readonly) NSManagedObjectContext *managedObjectContext;

- (void)saveContext;

@end
