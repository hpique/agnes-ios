//
//  HPNote.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote.h"

@implementation HPNote

+ (HPNote*)note
{
    HPNote *note = [[HPNote alloc] init];
    note.createdAt = [NSDate date];
    note.modifiedAt = note.createdAt;
    return note;
}

+ (HPNote*)noteWithText:(NSString*)text
{
    HPNote *note = [HPNote note];
    note.text = text;
    return note;
}

#pragma mark - Properties

- (BOOL)empty
{
    NSString *trimmedText = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmedText.length == 0;
}

- (NSString*)body
{
    if (!self.text) return nil;

    NSRange titleRange = [self.text rangeOfString:self.title];
    NSString *body = [self.text stringByReplacingCharactersInRange:titleRange withString:@""];
    NSString *trimmedBody = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmedBody;
}

- (NSString*)title
{
    if (!self.text) return nil;
    
    NSString *trimmedText = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *firstLine = [trimmedText componentsSeparatedByString:@"\n"][0];
    return firstLine;
}

@end
