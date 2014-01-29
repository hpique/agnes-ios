//
//  HPPreferencesManager.h
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPNoteManager.h"

extern NSString* const HPPreferencesManagerDidChangePreferencesNotification;

@interface HPPreferencesManager : NSObject

+ (HPPreferencesManager*)sharedManager;

- (HPTagSortMode)sortModeForListTitle:(NSString*)title default:(HPTagSortMode)defaultSortMode;

- (void)setSortMode:(HPTagSortMode)mode forListTitle:(NSString*)title;

- (NSInteger)increaseSessionCount;

- (void)applyPreferences:(NSString*)preferences;

@property (nonatomic, readonly) NSInteger sessionCount;
@property (nonatomic, strong) UIColor *barTintColor;
@property (nonatomic, readonly) NSString *barTintColorName;
@property (nonatomic, assign) BOOL statusBarHidden;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, readonly) NSString *tintColorName;

@end
