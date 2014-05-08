//
//  HPTracker.h
//  Agnes
//
//  Created by Hermes on 19/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HPTracker : NSObject

+ (HPTracker*)defaultTracker;

+ (void)setDebug:(BOOL)debug;

- (void)setToPreviousScreen;

- (void)setTrackingId:(NSString*)trackingId;

- (void)trackScreenWithName:(NSString*)screenName;

- (void)trackEventWithCategory:(NSString*)category action:(NSString*)action;

- (void)trackEventWithCategory:(NSString*)category action:(NSString*)action label:(NSString*)label;

- (void)trackEventWithCategory:(NSString*)category action:(NSString*)action label:(NSString*)label value:(NSNumber*)value;

@end
