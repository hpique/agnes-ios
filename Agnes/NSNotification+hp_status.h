//
//  NSNotification+hp_status.h
//  Agnes
//
//  Created by Hermes on 21/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const HPStatusNotification;

@interface NSNotification (hp_status)

@property (nonatomic, readonly) NSString *hp_statuslocalizedMessage;
@property (nonatomic, readonly) BOOL hp_statusTransient;

@end

@interface NSNotificationCenter (hp_status)

- (void)hp_postStatus:(NSString*)localizedMessage transient:(BOOL)transient object:(id)object;

@end