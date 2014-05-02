//
//  AGNPreferenceManager.h
//  Agnes
//
//  Created by Hermes on 23/02/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPEntityManager.h"

@interface AGNPreferenceManager : HPEntityManager

+ (AGNPreferenceManager*)sharedManager;

@property (nonatomic, assign) BOOL tutorialNotesAdded;

- (void)removeDuplicates;

@end
