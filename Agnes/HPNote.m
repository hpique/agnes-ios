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
#import "HPAttachment.h" 
#import "HPData.h"
#import "NSString+hp_utils.h"

NSString* const HPNoteAttachmentAttributeName = @"HPNoteAttachment";
const NSInteger HPNoteDetailModeCount = 5;

@implementation HPNote {
    NSString *_body;
    NSString *_title;
}

@dynamic cd_attachments;
@dynamic cd_archived;
@dynamic cd_detailMode;
@dynamic cd_inboxOrder;
@dynamic cd_views;
@dynamic cd_tags;
@dynamic createdAt;
@dynamic modifiedAt;
@dynamic tagOrder;
@dynamic text;

@synthesize tags = _tags;

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
        NSString* pattern = @"(?<!\\S)#\\w+";
        instance = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    });
    return instance;
}

+ (NSString*)textOfBlankNoteWithTagOfName:(NSString*)tag
{
    return [NSString stringWithFormat:@"\n\n\n\n%@", tag];
}

- (BOOL)isNew
{
    return self.managedObjectContext == nil;
}

- (BOOL)empty
{
    NSString *trimmedText = [self.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return trimmedText.length == 0;
}

- (NSString*)firstTagName
{
    return [self.tags firstObject];
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
{ // TODO: Find a better place for this logic
    if (self.managedObjectContext == nil) return; // Do nothing for blank notes
    
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
    [self addCd_tags:currentTags];
    
    // In theory this shouldn't be necessary but I couldn't make it to work without it. See: http://stackoverflow.com/questions/21314770/core-data-does-not-update-inverse-relationship
    for (HPTag *tag in currentTags)
    {
        [tag addCd_notesObject:self];
    }
    for (HPTag *tag in previousTags)
    {
        [tag removeCd_notesObject:self];
    }

    for (HPTag *tag in previousTags)
    {
        if (tag.cd_notes.count == 0)
        {
            [manager.context deleteObject:tag];
        }
    }
}

@end

@implementation HPNote(Attachments)

- (NSArray*)attachments
{
    static NSArray *sortDescriptors = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(order)) ascending:YES];
        sortDescriptors = @[sortDescriptor];
    });
    NSArray *attachments = [self.cd_attachments sortedArrayUsingDescriptors:sortDescriptors];
    return attachments;
}

+ (NSString*)attachmentString
{
    static NSString *attachmentString = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        const unichar attachmentChar = NSAttachmentCharacter;
        attachmentString = [NSString stringWithCharacters:&attachmentChar length:1];
    });
    return attachmentString;
}

- (void)addAttachment:(HPAttachment*)attachment atIndex:(NSUInteger)index
{
    NSString *text = self.text;
    NSRange searchRange = NSMakeRange(0, index);
    NSUInteger attachmentIndex = [text hp_numberOfOccurencesOfString:[HPNote attachmentString] range:searchRange];
    attachmentIndex = MIN(attachmentIndex, self.attachments.count);
    
    NSMutableString *mutableText = [self.text mutableCopy];
    [mutableText insertString:@"\n" atIndex:index];
    [mutableText insertString:[HPNote attachmentString] atIndex:index];
    if (index > 0)
    {
        [mutableText insertString:@"\n" atIndex:index];
    }
    NSMutableArray *mutableAttachments = self.attachments.mutableCopy;
    [mutableAttachments insertObject:attachment atIndex:attachmentIndex];
    [self replaceAttachments:mutableAttachments];
    self.text = mutableText;
}

- (void)replaceAttachments:(NSArray*)attachments
{
    NSMutableSet *removedAttachments = self.cd_attachments.mutableCopy;
    [removedAttachments minusSet:[NSSet setWithArray:attachments]];
    for (HPAttachment *attachment in removedAttachments)
    {
        [self.managedObjectContext deleteObject:attachment];
    }
    [attachments enumerateObjectsUsingBlock:^(HPAttachment *attachment, NSUInteger idx, BOOL *stop) {
        attachment.order = idx;
        attachment.note = self; // TODO: Why is this necessary? See: http://stackoverflow.com/questions/21518469/core-data-does-not-save-one-to-many-relationship
    }];
    
    // Core Data NSOrderedSet generated accesors are broken as of iOS 7. See: http://stackoverflow.com/questions/7385439/exception-thrown-in-nsorderedset-generated-accessors
    NSMutableSet *mutableAttachments = [self mutableSetValueForKey:NSStringFromSelector(@selector(cd_attachments))];
    [mutableAttachments removeAllObjects];
    [mutableAttachments addObjectsFromArray:attachments];
}

@end

@implementation HPNote(View)

- (NSString*)body
{
    if (!self.text) return nil;
    if (!_body)
    {
        NSString *text = [self.text stringByReplacingOccurrencesOfString:[HPNote attachmentString] withString:@""];
        NSString *title = self.title;
        NSRange titleRange = [text rangeOfString:title];
        NSString *body;
        if (titleRange.location != NSNotFound)
        {
            body = [text stringByReplacingCharactersInRange:titleRange withString:@""];
        }
        _body = [body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return _body;
}

- (NSString*)bodyForTagWithName:(NSString*)tagName
{
    NSString *body = self.body;
    if (!tagName) return body;
    if (body.length == 0) return body;
    NSRange lastLineRange = [body lineRangeForRange:NSMakeRange(body.length - 1, 1)];
    NSString *lastLine = [body substringWithRange:lastLineRange];
    if (![lastLine isEqualToString:tagName]) return body;
    NSString *bodyForTag = [body stringByReplacingCharactersInRange:lastLineRange withString:@""];
    bodyForTag = [bodyForTag stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return bodyForTag;
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

- (NSString*)modifiedAtLongDescription
{
    static NSDateFormatter *formatter;
    if (!formatter)
    {
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterLongStyle;
        formatter.doesRelativeDateFormatting = YES;
        formatter.locale = [NSLocale currentLocale];
    }
    return [formatter stringFromDate:self.modifiedAt];
}

- (NSString*)title
{
    if (!self.text) return nil;
    if (!_title)
    {
        NSString *text = [self.text stringByReplacingOccurrencesOfString:[HPNote attachmentString] withString:@""];
        NSString *trimmedText = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        _title = [trimmedText componentsSeparatedByString:@"\n"][0];
        if (_title.length == 0 && self.attachments.count > 0)
        {
            _title = NSLocalizedString(@"Untitled note", @"");
        }
    }
    return _title;
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

- (NSInteger)detailMode
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(detailMode));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_detailMode;
    [self didAccessValueForKey:key];
    return [value integerValue];
}

- (void)setDetailMode:(NSInteger)detailMode
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(detailMode));
    
    NSNumber *value = @(detailMode);
    [self willChangeValueForKey:key];
    self.cd_detailMode = value;
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
