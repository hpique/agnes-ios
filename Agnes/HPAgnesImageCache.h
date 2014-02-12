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

@interface HPAttachment(HPImageCacheEntity)<HNKCacheEntity>

@end

@interface HPAgnesImageCache : NSObject

+ (HPAgnesImageCache*)sharedCache;

- (UIImage*)noteDetailImageForAttachment:(HPAttachment*)attachment;

@end
