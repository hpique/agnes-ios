//
//  AGNPreference.h
//  Agnes
//
//  Created by Hermes on 23/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AGNPreference : NSManagedObject

@property (nonatomic, retain) NSString * key;
@property (nonatomic, retain) NSString * value;

@end

@interface AGNPreference(CoreDataHelpers)

+ (NSString *)entityName;

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context;

@end