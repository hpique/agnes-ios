//
//  HPAttachment.h
//  Agnes
//
//  Created by Hermes on 30/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class HPData, HPNote;

@interface HPAttachment : NSManagedObject

@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) HPNote *note;
@property (nonatomic, retain) HPData *data;
@property (nonatomic, retain) HPData *thumbnail;

@end

@interface HPAttachment(Convenience)

+ (NSString *)entityName;

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context;

@end