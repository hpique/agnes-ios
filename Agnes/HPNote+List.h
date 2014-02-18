//
//  HPNote+List.h
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote.h"
@class HPAttachment;
@class HPTag;

@interface HPNote (List)

/**
 Guess if the note has a thumbnail by searching for the attachment string. This is much faster than hasThumbnail as it doesn't require loading the attachments.
 */
@property (nonatomic, readonly) BOOL mightHaveThumbnail;
@property (nonatomic, readonly) BOOL hasThumbnail;
@property (nonatomic, readonly) HPAttachment *thumbnailAttachment;

- (NSString*)summaryForTag:(HPTag*)tag;

@end
