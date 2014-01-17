//
//  HPNoteManager.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteManager.h"

@implementation HPNoteManager {
    NSMutableArray *_notes;
}

- (id) init
{
    if (self = [super init])
    {
        _notes = [NSMutableArray array];
    }
    return self;
}

- (NSArray*)notes
{
    return [NSArray arrayWithArray:_notes];
}

- (void)addNote:(HPNote *)note
{
    [_notes addObject:note];
}

- (void)removeNote:(HPNote*)note
{
    [_notes removeObject:note];
}

+ (HPNoteManager*)sharedManager
{
    static HPNoteManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HPNoteManager alloc] init];
    });
    return instance;
}

@end
