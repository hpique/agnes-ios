//
//  HPTagManager.h
//  Agnes
//
//  Created by Hermes on 20/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HPEntityManager.h"
@class HPTag;

@interface HPTagManager : HPEntityManager

- (NSArray*)tagNamesWithPrefix:(NSString*)prefix;

- (HPTag*)tagWithName:(NSString*)name;

+ (HPTagManager*)sharedManager;

- (void)reorderTagsWithNames:(NSArray*)names;

@end
