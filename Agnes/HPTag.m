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

@dynamic cd_notes;
@dynamic cd_order;
@dynamic name;
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

- (NSInteger)order
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(order));
    
    [self willAccessValueForKey:key];
    NSNumber *value = self.cd_order;
    [self didAccessValueForKey:key];
    return [value integerValue];
}

- (void)setOrder:(NSInteger)order
{
    static NSString *key = nil;
    if (!key) key = NSStringFromSelector(@selector(order));
    
    NSNumber *value = @(order);
    [self willChangeValueForKey:key];
    self.cd_order = value;
    [self willChangeValueForKey:key];
}
@end