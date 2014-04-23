//
//  HPDispatchUtils.m
//  Agnes
//
//  Created by Hermés Piqué on 23/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPDispatchUtils.h"

void HPDispatchSyncInMainQueueIfNeeded(dispatch_block_t block)
{
    if ([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}
