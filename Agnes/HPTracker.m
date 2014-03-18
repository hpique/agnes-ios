//
//  HPTracker.m
//  Agnes
//
//  Created by Hermes on 19/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPTracker.h"

#import "GAI.h"
#import "GAIFields.h"
#import "GAIDictionaryBuilder.h"

@implementation HPTracker {
    id<GAITracker> _tracker;
    NSMutableArray *_screenHistory;
}

- (id)init
{
    if (self = [super init])
    {
        _screenHistory = [NSMutableArray array];
    }
    return self;
}

+ (HPTracker*)defaultTracker
{
    static HPTracker *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[[self class] alloc] init];
    });
    return sharedInstance;
}

- (void)setToPreviousScreen
{
    NSCAssert(_screenHistory.count > 0, @"Attempting to dismiss a screen with an empty history.");
    
    [_screenHistory removeLastObject];
    NSString *screenName = [_screenHistory lastObject];
    [_tracker set:kGAIScreenName value:screenName];
}

- (void)setTrackingId:(NSString*)trackingId
{
    _tracker = [[GAI sharedInstance] trackerWithTrackingId:trackingId];
}

- (void)trackScreenWithName:(NSString*)screenName
{
    NSCAssert(_tracker, @"Tracking id required");
    
    [_tracker set:kGAIScreenName value:screenName];
    [_screenHistory addObject:screenName];
    GAIDictionaryBuilder *builder = [GAIDictionaryBuilder createAppView];
    NSDictionary *parameters = [builder build];
    [_tracker send:parameters];
}

- (void)trackEventWithCategory:(NSString*)category action:(NSString*)action
{
    [self trackEventWithCategory:category action:action label:nil];
}

- (void)trackEventWithCategory:(NSString*)category action:(NSString*)action label:(NSString*)label
{
    [self trackEventWithCategory:category action:action label:label value:nil];
}

- (void)trackEventWithCategory:(NSString*)category action:(NSString*)action label:(NSString*)label value:(NSNumber*)value
{
    NSCAssert(_tracker, @"Tracking id required");
    
    GAIDictionaryBuilder *builder = [GAIDictionaryBuilder createEventWithCategory:category action:action label:label value:value];
    NSDictionary *parameters = [builder build];
    [_tracker send:parameters];
}

@end
