//
//  HPNote.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote.h"

@implementation HPNote

#pragma mark - Properties

- (NSString*)title
{
    if (!self.body) return nil;
    
    NSString *trimmedBody = [self.body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *firstLine = [trimmedBody componentsSeparatedByString:@"\n"][0];
    return firstLine;
}


+ (HPNote*)note
{
    HPNote *note = [[HPNote alloc] init];
    note.createdAt = [NSDate date];
    note.modifiedAt = note.createdAt;
    return note;
}

+ (HPNote*)noteWithBody:(NSString*)body
{
    HPNote *note = [HPNote note];
    note.body = body;
    return note;
}

@end
