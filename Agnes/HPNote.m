//
//  HPNote.m
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNote.h"
#import "HPTag.h"
#import "HPTagManager.h"

@implementation HPNote

@dynamic cd_archived;
@dynamic cd_inboxOrder;
@dynamic cd_views;
@dynamic cd_tags;
@dynamic createdAt;
@dynamic modifiedAt;
@dynamic tagOrder;
@dynamic text;

@synthesize body = _body;
@synthesize tags = _tags;
@synthesize title = _title;

#pragma mark - Public

- (NSString*)debugDescription
{
    return self.title;
}

#pragma mark - NSManagedObject

// See: http://stackoverflow.com/questions/21231908/calculated-properties-in-core-data

- (void)setText:(NSString *)text
{
    static NSString *key;
    if (!key) key = NSStringFromSelector(@selector(text));
    [self willChangeValueForKey:key];
    [self setPrimitiveText:text];
    _title = nil;
    _body = nil;
    _tags = nil;
    [self updateTags];
    [self didChangeValueForKey:key];
}

- (void)awakeFromSnapshotEvents:(NSSnapshotEventType)flags
{
    [super awakeFromSnapshotEvents:flags];
    [self updateTags];
}

- (void)willChangeValueForKey:(NSString *)key
{
    [super willChangeValueForKey:key];
    static NSString *textKey;
    if (!textKey) textKey = NSStringFromSelector(@selector(text));
    if ([key isEqualToString:textKey])
    {
        _title = nil;
        _body = nil;
        _tags = nil;
    }
}

#pragma mark - Public

+ (NSString *)entityName
{
    return @"Note";
}

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                         inManagedObjectContext:context];
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

+ (NSString*)textOfBlankNoteWithTag:(NSString*)tag
{
    return [NSString stringWithFormat:@"\n\n\n\n%@", tag];
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
    if (interval < 2) return [NSString stringWithFormat:NSLocalizedString(@"now", @""), interval];
    if (interval < 60) return [NSString stringWithFormat:NSLocalizedString(@"%.0lfs", @""), interval];
    if (interval < 3600) return [NSString stringWithFormat:NSLocalizedString(@"%.0lfm", @""), interval / 60];
    if (interval < 86400) return [NSString stringWithFormat:NSLocalizedString(@"%.0lfh", @""), interval / 3600];
    if (interval < 31556926) return [NSString stringWithFormat:NSLocalizedString(@"%.0lfd", @""), interval / 86400];
    return [NSString stringWithFormat:NSLocalizedString(@"%.0lfy", @""), interval / 31556926];
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

- (void)setOrder:(NSInteger)order inTag:(NSString*)tag;
{
    if (!tag)
    {
        self.inboxOrder = order;
    }
    else
    {
        NSMutableDictionary *dictionary = self.tagOrder ? [NSMutableDictionary dictionaryWithDictionary:self.tagOrder] : [NSMutableDictionary dictionary];
        [dictionary setObject:@(order) forKey:tag];
        self.tagOrder = dictionary;
    }
}

- (NSInteger)orderInTag:(NSString*)tag
{
    NSNumber *object;
    if (!tag)
    {
        object = self.cd_inboxOrder;
    }
    else
    {
        object = [self.tagOrder objectForKey:tag];
    }
    return object ? [object integerValue] : NSIntegerMax;
}

#pragma mark - Private

- (void)updateTags
{
    NSArray *currentTagNames = self.tags;
    NSMutableSet *currentTags = [NSMutableSet set];
    HPTagManager *manager = [HPTagManager sharedManager];
    for (NSString *name in currentTagNames)
    {
        HPTag *tag = [manager tagWithName:name];
        [currentTags addObject:tag];
    }
    NSMutableSet *previousTags = [NSMutableSet setWithSet:self.cd_tags];
    [previousTags minusSet:currentTags]; // Removed
    [currentTags minusSet:self.cd_tags]; // Added
    [self removeCd_tags:previousTags];
    
    // TODO: Find a better place for this logic
    for (HPTag *tag in previousTags)
    {
        if (tag.notes.count == 0)
        {
            [manager.context deleteObject:tag];
        }
    }
    [self addCd_tags:currentTags];
}

@end

@implementation HPNote(Transient)

- (BOOL)archived
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(archived));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_archived;
    [self didAccessValueForKey:key];
    return [value boolValue];
}

- (void)setArchived:(BOOL)archived
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(archived));
    
    NSNumber *value = @(archived);
    [self willChangeValueForKey:key];
    self.cd_archived = value;
    [self willChangeValueForKey:key];
}

- (NSInteger)views
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(views));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_views;
    [self didAccessValueForKey:key];
    return [value integerValue];
}

- (void)setViews:(NSInteger)views
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(views));
    
    NSNumber *value = @(views);
    [self willChangeValueForKey:key];
    self.cd_views = value;
    [self willChangeValueForKey:key];
}

- (NSInteger)inboxOrder
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(inboxOrder));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_inboxOrder;
    [self didAccessValueForKey:key];
    return [value integerValue];
}

- (void)setInboxOrder:(NSInteger)inboxOrder
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(inboxOrder));

    NSNumber *value = @(inboxOrder);
    [self willChangeValueForKey:key];
    self.cd_inboxOrder = value;
    [self willChangeValueForKey:key];
}

@end
