//
//  HPNote+List.m
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote+List.h"
#import "HPAttachment.h"
#import "HPTag.h"

@implementation HPNote (List)

- (BOOL)hasThumbnail
{
    return self.thumbnailAttachment != nil;
}

- (BOOL)mightHaveThumbnail
{
    const NSRange range = [self.text rangeOfString:[HPNote attachmentString]];
    return range.location != NSNotFound;
}

- (NSString*)summaryForTag:(HPTag*)tag
{
    NSString *summary = self.summary;
    if (!tag) return summary;

    if (summary.length == 0) return summary;
    
    if (tag.isSystem) return summary;
    
    NSRange lastLineRange = [summary lineRangeForRange:NSMakeRange(summary.length - 1, 1)];
    NSString *lastLine = [summary substringWithRange:lastLineRange];
    if (![lastLine isEqualToString:tag.name]) return summary;
    
    NSString *summaryForTag = [summary stringByReplacingCharactersInRange:lastLineRange withString:@""];
    summaryForTag = [summaryForTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (summaryForTag.length > 0) return summaryForTag;
    
    NSString *body = self.body;
    const NSRange summaryRange = [body rangeOfString:summary];
    const NSUInteger index = NSMaxRange(summaryRange);
    if (index >= body.length) return summaryForTag;
    
    NSString *altSummary = [body substringFromIndex:index];
    altSummary = [altSummary stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return altSummary;
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
