//
//  HPPreferencesManager.h
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPNoteManager.h"

@interface HPPreferencesManager : NSObject

+ (HPPreferencesManager*)sharedManager;

- (HPNoteDisplayCriteria)displayCriteriaForListTitle:(NSString*)title default:(HPNoteDisplayCriteria)defaultDisplayCriteria;

- (void)setDisplayCriteria:(HPNoteDisplayCriteria)displayCriteria forListTitle:(NSString*)title;

- (NSInteger)increaseSessionCount;

@property (nonatomic, readonly) NSInteger sessionCount;
@property (nonatomic, readonly) UIColor *tintColor;

@end
