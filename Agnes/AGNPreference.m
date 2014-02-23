//
//  AGNPreference.m
//  Agnes
//
//  Created by Hermes on 23/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNPreference.h"

@implementation AGNPreference

@dynamic key;
@dynamic value;

@end

@implementation AGNPreference(CoreDataHelpers)

+ (NSString *)entityName
{
    return @"Preference";
}

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                         inManagedObjectContext:context];
}

@end