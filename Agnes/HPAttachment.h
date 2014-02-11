//
//  HPAttachment.h
//  Agnes
//
//  Created by Hermes on 30/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSInteger, HPAttachmentMode) {
    HPAttachmentModeDefault = 0,
    HPAttachmentModeCharacter = 1,
};

@class HPData, HPNote;

@interface HPAttachment : NSManagedObject

@property (nonatomic, retain) NSNumber * cd_mode;
@property (nonatomic, retain) NSNumber * cd_order;
@property (nonatomic, retain) NSDate * createdAt;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) HPNote *note;
@property (nonatomic, retain) HPData *data;
@property (nonatomic, retain) NSString *uuid;

@property (nonatomic, readonly) UIImage *image;

+ (HPAttachment*)attachmentWithImage:(UIImage*)image context:(NSManagedObjectContext*)context;

@end

@interface HPAttachment(Convenience)

+ (NSString *)entityName;

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context;

@end

@interface HPAttachment (Transient)

@property (nonatomic, assign) HPAttachmentMode mode;
@property (nonatomic, assign) NSInteger order;

@end
