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

@property (nonatomic, readonly) BOOL hasThumbnail;
@property (nonatomic, readonly) HPAttachment *thumbnailAttachment;

- (NSString*)summaryForTag:(HPTag*)tag;

@end
