//
//  HPNote.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote.h"

@implementation HPNote {
    NSString *_body;
    NSString *_title;
    
    NSSet *_addedTags;
    NSArray *_tags;
    NSSet *_removedTags;
    
    NSMutableDictionary *_orderInTags;
}

- (id)init
{
    if (self = [super init])
    {
        _addedTags = [NSSet set];
        _removedTags = [NSSet set];
        _orderInTags = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString*)debugDescription
{
    return self.title;
}

#pragma mark - Public

- (void)setOrder:(NSInteger)order inTag:(NSString*)tag;
{
    if (!tag)
    {
        self.order = order;
    }
    else
    {
        [_orderInTags setObject:@(order) forKey:tag];
    }
}

- (NSInteger)orderInTag:(NSString*)tag
{
    if (!tag)
    {
        return self.order;
    }
    else
    {
        return [[_orderInTags objectForKey:tag] integerValue];
    }
}

#pragma mark - Class

+ (HPNote*)blankNoteWithTag:(NSString*)tag
{
    HPNote *note = [HPNote note];
    if (tag)
    {
        note.text = [NSString stringWithFormat:@"\n\n\n\n%@", tag];
    }
    return note;
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

- (NSSet*)addedTags
{
    return _addedTags;
}

- (BOOL)empty
{
    NSString *trimmedText = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmedText.length == 0;
}

- (NSString*)body
{
    if (!self.text) return nil;
    if (!_body)
    {
        NSRange titleRange = [self.text rangeOfString:self.title];
        NSString *body = [self.text stringByReplacingCharactersInRange:titleRange withString:@""];
        _body = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return _body;
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

- (NSSet*)removedTags
{
    return _removedTags;
}

- (void)setText:(NSString *)text
{
    NSSet *previousTags = [NSSet setWithArray:self.tags];
    _text = text;
    _title = nil;
    _body = nil;
    _tags = nil;
    NSSet *currentTags = [NSSet setWithArray:self.tags];
    
    NSMutableSet *removedTags = [NSMutableSet setWithSet:previousTags];
    [removedTags minusSet:currentTags];
    _removedTags = removedTags;

    NSMutableSet *addedTags = [NSMutableSet setWithSet:currentTags];
    [addedTags minusSet:previousTags];
    _addedTags = addedTags;
}

- (NSArray*)tags
{
    if (!_tags)
    {
        NSMutableArray *tags = [NSMutableArray array];
        if (self.text)
        {
            NSRegularExpression *regex = [HPNote tagRegularExpression];
            NSRange range = NSMakeRange(0, self.text.length);
            [regex enumerateMatchesInString:self.text options:0 range:range usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
             {
                 NSRange matchRange = [match rangeAtIndex:0];
                 NSString *tag = [self.text substringWithRange:matchRange];
                 [tags addObject:tag];
             }];
        }
        _tags = tags;
    }
    return _tags;
}

- (NSString*)title
{
    if (!self.text) return nil;
    if (!_title)
    {
        NSString *trimmedText = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        _title = [trimmedText componentsSeparatedByString:@"\n"][0];
    }
    return _title;
}

@end
