//
//  HPNote+Thumbnail.m
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote+Thumbnail.h"
#import "HPAttachment.h"

@implementation HPNote (Thumbnail)

- (BOOL)hasThumbnail
{
    return self.thumbnailAttachment != nil;
}

- (HPAttachment*)thumbnailAttachment
{
    for (HPAttachment *attachment in self.attachments)
    {
        if (attachment.mode == HPAttachmentModeDefault) return attachment;
    }
    return nil;
}

- (UIImage*)thumbnail
{
    return self.thumbnailAttachment.thumbnail;
}

@end
