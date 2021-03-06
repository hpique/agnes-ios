//
//  HPTag.m
//  Agnes
//
//  Created by Hermes on 19/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPTag.h"
#import "HPNote.h"

@implementation HPTag

@dynamic cd_isSystem;
@dynamic cd_notes;
@dynamic cd_order;
@dynamic cd_sortMode;
@dynamic cd_views;
@dynamic name;
@dynamic uuid;
@dynamic viewedAt;

@end

@implementation HPTag (Convenience)

+ (NSString *)entityName
{
    return @"Tag";
}

+ (instancetype)insertNewObjectIntoContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                         inManagedObjectContext:context];
}

@end


@implementation HPTag(Transient)

- (CGFloat)order
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(order));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_order;
    [self didAccessValueForKey:key];
    return [value floatValue];
}

- (void)setOrder:(CGFloat)order
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(order));
    
    NSNumber *value = @(order);
    [self willChangeValueForKey:key];
    self.cd_order = value;
    [self didChangeValueForKey:key];
}

- (BOOL)isSystem
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(isSystem));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_isSystem;
    [self didAccessValueForKey:key];
    return [value boolValue];
}

- (void)setIsSystem:(BOOL)isSystem
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(isSystem));
    
    NSNumber *value = @(isSystem);
    [self willChangeValueForKey:key];
    self.cd_isSystem = value;
    [self didChangeValueForKey:key];
}

- (NSInteger)sortMode
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(sortMode));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_sortMode;
    [self didAccessValueForKey:key];
    return [value integerValue];
}

- (void)setSortMode:(NSInteger)sortMode
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(sortMode));
    
    NSNumber *value = @(sortMode);
    [self willChangeValueForKey:key];
    self.cd_sortMode = value;
    [self didChangeValueForKey:key];
}

- (NSUInteger)views
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(views));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_views;
    [self didAccessValueForKey:key];
    return [value unsignedIntegerValue];
}

- (void)setViews:(NSUInteger)views
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(views));
    
    NSNumber *value = @(views);
    [self willChangeValueForKey:key];
    self.cd_views = value;
    [self didChangeValueForKey:key];
}

@end