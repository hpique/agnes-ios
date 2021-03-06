//
//  AGNPreferencesManager.h
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPNoteManager.h"
#import "HPIndexItem.h"

extern NSString* const AGNPreferencesManagerDidChangePreferencesNotification;

@interface AGNPreferencesManager : NSObject

+ (AGNPreferencesManager*)sharedManager;

- (void)applyPreferences:(NSString*)preferences;

- (void)styleNavigationBar:(UINavigationBar*)navigationBar;

- (void)styleSearchBar;

- (void)styleStatusBar;

@property (nonatomic, assign) BOOL dynamicType;

@property (nonatomic, strong) UIColor *barTintColor;

@property (nonatomic, readonly) NSString *barTintColorName;

@property (nonatomic, readonly) UIColor *barForegroundColor;

@property (nonatomic, strong) NSString *fontName;

@property (nonatomic, assign) NSInteger fontSize;

@property (nonatomic, assign) HPIndexSortMode indexSortMode;

@property (nonatomic, copy) NSString *lastViewedTagName;

@property (nonatomic, assign) BOOL listSeparatorsHidden;

@property (nonatomic, assign) BOOL statusBarHidden;

@property (nonatomic, readonly) UIStatusBarStyle statusBarStyle;

@property (nonatomic, strong) UIColor *tintColor;

@property (nonatomic, readonly) NSString *tintColorName;

@end
