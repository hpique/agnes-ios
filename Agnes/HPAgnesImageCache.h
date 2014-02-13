//
//  HPAgnesImageCache.h
//  Agnes
//
//  Created by Hermes on 11/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPAttachment.h"
#import "HNKCache.h"

@interface HPAgnesImageCache : NSObject

+ (HPAgnesImageCache*)sharedCache;

@property (nonatomic, readonly) HNKCacheFormat *thumbnailFormat;

- (UIImage*)noteDetailImageForAttachment:(HPAttachment*)attachment;

- (void)prePopulateCacheWithThumbnailOfImageNamed:(NSString*)name atttachment:(HPAttachment*)attachment;

@end

@interface HPAttachment(HPImageCacheEntity)<HNKCacheEntity>

@end
