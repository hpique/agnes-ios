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

@dynamic name;
@dynamic notes;

- (BOOL)hasInboxNotes
{
    for (HPNote *note in self.notes)
    {
        if (!note.archived) return YES;
    }
    return NO;
}

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
