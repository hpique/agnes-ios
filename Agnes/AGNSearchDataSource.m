//
//  AGNSearchDataSource.m
//  Agnes
//
//  Created by Hermés Piqué on 02/04/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNSearchDataSource.h"
#import "HPIndexItem.h"
#import "HPNote.h"

NSComparisonResult AGNCompareSearchResults(NSString *text1, NSString *text2, NSString *search)
{
    NSRange range1 = [text1 rangeOfString:search options:NSCaseInsensitiveSearch];
    NSRange range2 = [text2 rangeOfString:search options:NSCaseInsensitiveSearch];
    NSUInteger location1 = range1.location == NSNotFound ? NSUIntegerMax : range1.location;
    NSUInteger location2 = range2.location == NSNotFound ? NSUIntegerMax : range2.location;
    if (location1 < location2) return NSOrderedAscending;
    if (location1 > location2) return NSOrderedDescending;
    return NSOrderedSame;
}

NSArray *AGNSearchIndexItem(HPIndexItem *indexItem, NSString *searchString, BOOL archived)
{
    if (searchString.length == 0) return @[];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.%@ contains[cd] %@ && SELF.%@ == %d",
                              NSStringFromSelector(@selector(text)),
                              searchString,
                              NSStringFromSelector(@selector(archived)),
                              archived ? 1 : 0];
    NSArray *unfilteredNotes = [indexItem notes:archived];
    if (!unfilteredNotes) unfilteredNotes = @[];
    NSArray *filteredNotes = [unfilteredNotes filteredArrayUsingPredicate:predicate];
    NSArray *rankedNotes = [filteredNotes sortedArrayUsingComparator:^NSComparisonResult(HPNote *obj1, HPNote *obj2)
                            {
                                NSComparisonResult result = AGNCompareSearchResults(obj1.title, obj2.title, searchString);
                                if (result != NSOrderedSame) return result;
                                result = AGNCompareSearchResults(obj1.body, obj2.body, searchString);
                                if (result != NSOrderedSame) return result;
                                return [obj1.modifiedAt compare:obj2.modifiedAt];
                            }];
    return rankedNotes;
}

@implementation AGNSearchDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 1 ? NSLocalizedString(@"Archived", @"") : nil;
}

#pragma mark Public

- (instancetype)initWithSearch:(NSString*)search
                     indexItem:(HPIndexItem*)indexItem
                cellIdentifier:(NSString *)cellIdentifier
{
    NSArray *inboxResults = AGNSearchIndexItem(indexItem, search, NO);
    NSArray *archivedResults = AGNSearchIndexItem(indexItem, search, YES);
    NSArray *sections = archivedResults.count > 0 ? @[inboxResults, archivedResults] : @[inboxResults];

    self = [super initWithSections:sections cellIdentifier:cellIdentifier];
    return self;
}

- (NSArray*)inboxResults
{
    return [self itemsAtSection:0];
}

- (NSArray*)archivedResults
{
    return self.sections.count > 1 ? [self itemsAtSection:1] : nil;
}

@end
