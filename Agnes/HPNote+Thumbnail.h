//
//  HPNote+Thumbnail.h
//  Agnes
//
//  Created by Hermes on 03/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote.h"
@class HPAttachment;

@interface HPNote (Thumbnail)

@property (nonatomic, readonly) BOOL hasThumbnail;
@property (nonatomic, readonly) HPAttachment *thumbnailAttachment;

@end
