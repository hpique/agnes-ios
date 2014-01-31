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