//
//  HPAttachment.m
//  Agnes
//
//  Created by Hermes on 30/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAttachment.h"
#import "HPData.h"
#import "HPNote.h"
#import "HPNoteManager.h"
#import "UIImage+hp_utils.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation HPAttachment

@dynamic createdAt;
@dynamic type;
@dynamic note;
@dynamic data;
@dynamic thumbnailData;

#pragma mark - Public

- (UIImage*)image
{
    NSData *data = self.data.data;
    UIImage *image = [UIImage imageWithData:data];
    return image;
}

- (UIImage*)thumbnail
{
    NSAssert(self.thumbnailData, @"No thumbnail");
    UIImage *thumbnail = nil;
    if (self.thumbnailData)
    {
        NSData *data = self.thumbnailData.data;
        thumbnail = [UIImage imageWithData:data];
    }
    NSAssert(thumbnail, @"Invalid thumbnail data");
    if (!thumbnail)
    {
        thumbnail = self.image;
    }
    return thumbnail;
}

+ (HPAttachment*)attachmentWithImage:(UIImage*)image context:(NSManagedObjectContext*)context
{
    NSManagedObjectContext *modelContext = [HPNoteManager sharedManager].context;
    NSEntityDescription *entityAttachment = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:modelContext];
    HPAttachment *attachment = [[HPAttachment alloc] initWithEntity:entityAttachment insertIntoManagedObjectContext:context];
    attachment.type = (NSString*) kUTTypeImage;
    
    NSEntityDescription *entityData = [NSEntityDescription entityForName:[HPData entityName] inManagedObjectContext:modelContext];
    HPData *modelData = [[HPData alloc] initWithEntity:entityData insertIntoManagedObjectContext:attachment.managedObjectContext];
    modelData.data = UIImageJPEGRepresentation(image, 1);
    attachment.data = modelData;
    
    {
        CGSize thumbnailSize;
        CGSize imageSize = image.size;
        if (imageSize.height < imageSize.width)
        {
            thumbnailSize.height = 240;
            thumbnailSize.width = imageSize.width / (imageSize.height / thumbnailSize.height);
        }
        else
        {
            thumbnailSize.width = 240;
            thumbnailSize.height = imageSize.height / (imageSize.width / thumbnailSize.width);
        }
        UIImage *thumbnail = [UIImage hp_imageWithImage:image scaledToSize:thumbnailSize];
        HPData *thumbnailModelData = [[HPData alloc] initWithEntity:entityData insertIntoManagedObjectContext:attachment.managedObjectContext];
        thumbnailModelData.data = UIImageJPEGRepresentation(thumbnail, 1);
        attachment.thumbnailData = thumbnailModelData;
    }
    
    attachment.createdAt = [NSDate date];
    return attachment;
}

@end

@implementation HPAttachment(Convenience)

+ (NSString *)entityName
{
    return @"Attachment";
}

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
}

@end