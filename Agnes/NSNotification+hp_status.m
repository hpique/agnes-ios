//
//  NSNotification+hp_status.m
//  Agnes
//
//  Created by Hermes on 21/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "NSNotification+hp_status.h"

NSString *const HPStatusNotification = @"HPStatusNotification";
NSString *const HPStatusUserInfoLocalizedMessageKey = @"HPStatusUserInfoLocalizedMessage";
NSString *const HPStatusUserInfoTransientKey = @"HPStatusUserInfoTransient";

@implementation NSNotification (hp_status)

- (NSString*)hp_statuslocalizedMessage
{
    return self.userInfo[HPStatusUserInfoLocalizedMessageKey];
}

- (BOOL)hp_statusTransient
{
    return [self.userInfo[HPStatusUserInfoTransientKey] boolValue];
}

@end

@implementation NSNotificationCenter (hp_status)

- (void)hp_postStatus:(NSString *)status transient:(BOOL)transient object:(id)object
{
    NSDictionary *userInfo = @{HPStatusUserInfoLocalizedMessageKey : status, HPStatusUserInfoTransientKey : @(transient)};
    [self postNotificationName:HPStatusNotification object:object userInfo:userInfo];
}

@end