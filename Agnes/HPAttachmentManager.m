//
//  HPAttachmentManager.m
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPAttachmentManager.h"
#import "HPAttachment.h"
#import "AGNAppDelegate.h"

@implementation HPAttachmentManager

- (NSString*)entityName
{
    return [HPAttachment entityName];
}

#pragma mark - Class

+ (HPAttachmentManager*)sharedManager
{
    static HPAttachmentManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AGNAppDelegate *appDelegate = (AGNAppDelegate*)[UIApplication sharedApplication].delegate;
        instance = [[HPAttachmentManager alloc] initWithManagedObjectContext:appDelegate.managedObjectContext];
    });
    return instance;
}

@end
