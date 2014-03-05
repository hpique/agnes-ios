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

const CGFloat AGNAttachmentImageQuality = 0.75;

@implementation HPAttachment

@dynamic cd_mode;
@dynamic cd_order;
@dynamic createdAt;
@dynamic type;
@dynamic note;
@dynamic data;
@dynamic uuid;

#pragma mark - Public

- (UIImage*)image
{
    NSData *data = self.data.data;
    UIImage *image = [UIImage imageWithData:data];
    return image;
}

+ (HPAttachment*)attachmentWithImage:(UIImage*)image context:(NSManagedObjectContext*)context
{
    NSData *data = UIImageJPEGRepresentation(image, AGNAttachmentImageQuality);
    HPAttachment *attachment = [HPAttachment attachmentWithData:data type:(NSString*)kUTTypeImage context:context];
    return attachment;
}

+ (HPAttachment*)attachmentWithData:(NSData*)data type:(NSString*)type context:(NSManagedObjectContext*)context
{
    NSManagedObjectContext *modelContext = [HPNoteManager sharedManager].context;
    NSEntityDescription *entityAttachment = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:modelContext];
    HPAttachment *attachment = [[HPAttachment alloc] initWithEntity:entityAttachment insertIntoManagedObjectContext:context];
    attachment.uuid = [[NSUUID UUID] UUIDString];
    attachment.type = type;

    NSEntityDescription *entityData = [NSEntityDescription entityForName:[HPData entityName] inManagedObjectContext:modelContext];
    HPData *modelData = [[HPData alloc] initWithEntity:entityData insertIntoManagedObjectContext:attachment.managedObjectContext];
    modelData.data = data;
    attachment.data = modelData;
    
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

@implementation HPAttachment(Transient)

- (HPAttachmentMode)mode
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(mode));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_mode;
    [self didAccessValueForKey:key];
    return [value integerValue];
}

- (void)setMode:(HPAttachmentMode)mode
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(mode));
    
    NSNumber *value = @(mode);
    [self willChangeValueForKey:key];
    self.cd_mode = value;
    [self willChangeValueForKey:key];
}

- (NSInteger)order
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(order));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_order;
    [self didAccessValueForKey:key];
    return [value integerValue];
}

- (void)setOrder:(NSInteger)order
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(order));
    
    NSNumber *value = @(order);
    [self willChangeValueForKey:key];
    self.cd_order = value;
    [self willChangeValueForKey:key];
}

@end
