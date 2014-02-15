//
//  HPNote+List.m
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote+List.h"
#import "HPAttachment.h"
#import "HPTagManager.h"
#import "HPTag.h"

@implementation HPNote (List)

- (BOOL)hasThumbnail
{
    return self.thumbnailAttachment != nil;
}

- (NSString*)summaryForTag:(HPTag*)tag
{
    NSString *summary = self.summary;
    if (!tag) return summary;

    if (summary.length == 0) return summary;
    
    HPTagManager *manager = [HPTagManager sharedManager];
    if (tag == manager.inboxTag || tag == manager.archiveTag) return summary;
    
    NSRange lastLineRange = [summary lineRangeForRange:NSMakeRange(summary.length - 1, 1)];
    NSString *lastLine = [summary substringWithRange:lastLineRange];
    if (![lastLine isEqualToString:tag.name]) return summary;
    
    NSString *summaryForTag = [summary stringByReplacingCharactersInRange:lastLineRange withString:@""];
    summaryForTag = [summaryForTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return summaryForTag;
}

- (HPAttachment*)thumbnailAttachment
{
    for (HPAttachment *attachment in self.attachments)
    {
        if (attachment.mode == HPAttachmentModeDefault) return attachment;
    }
    return nil;
}

@end
