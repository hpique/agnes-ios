//
//  HPNote.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote.h"

@implementation HPNote

- (NSString*)debugDescription
{
    return self.title;
}

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

+ (NSRegularExpression*)tagRegularExpression
{
    static NSRegularExpression *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* pattern = @"#\\w+";
        instance = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    });
    return instance;
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

- (NSString*)modifiedAtDescription
{
    NSTimeInterval interval = -[self.modifiedAt timeIntervalSinceNow];
    if (interval < 2) {
        return [NSString stringWithFormat:NSLocalizedString(@"now", @""), interval];
    } else if (interval < 60) {
        return [NSString stringWithFormat:NSLocalizedString(@"%.0lfs", @""), interval];
    } else if (interval < 3600) {
        return [NSString stringWithFormat:NSLocalizedString(@"%.0lfm", @""), interval / 60];
    } else if (interval < 86400) {
        return [NSString stringWithFormat:NSLocalizedString(@"%.0lfh", @""), interval / 3600];
    } else if (interval < 31556926) {
        return [NSString stringWithFormat:NSLocalizedString(@"%.0lfd", @""), interval / 86400];
    } else {
        return [NSString stringWithFormat:NSLocalizedString(@"%.0lfy", @""), interval / 31556926];
    }
}

- (NSString*)title
{
    if (!self.text) return nil;
    
    NSString *trimmedText = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *firstLine = [trimmedText componentsSeparatedByString:@"\n"][0];
    return firstLine;
}

@end
