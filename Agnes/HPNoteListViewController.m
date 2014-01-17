//
//  HPNoteListViewController.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteListViewController.h"
#import "HPNoteViewController.h"
#import "HPNoteManager.h"
#import "HPNote.h"
#import "HPNoteTableViewCell.h"

@interface HPNoteListViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation HPNoteListViewController {
    __weak IBOutlet UITableView *_tableView;
    NSArray *_notes;
    
    BOOL _searching;
    NSString *_searchString;
    NSArray *_searchResults;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"All Notes", @"");
    
    UIBarButtonItem *addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    self.navigationItem.rightBarButtonItem = addNoteBarButtonItem;
    [_tableView registerClass:[HPNoteTableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNotes]; // TODO: Should we call this the first time?
}

- (void)updateNotes
{ // TODO: This should be a notification.
    NSArray *previousNotes = _notes;
    _notes = [HPNoteManager sharedManager].notes;

    [self updateTableView:_tableView previousData:previousNotes updatedData:_notes];
    if (_searching && _searchString != nil)
    {
        NSArray *previousSearchResults = _searchResults;
        _searchResults = [self notesWithSearchString:_searchString];
        [self updateTableView:self.searchDisplayController.searchResultsTableView previousData:previousSearchResults updatedData:_searchResults];
    }
}

#pragma mark - Actions

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self showNote:nil];
}

#pragma mark - Private

- (void)updateTableView:(UITableView*)tableView previousData:(NSArray*)previousData updatedData:(NSArray*)updatedData
{
    NSArray *indexPathsToDelete = [self indexPathsOfArray:previousData notInArray:updatedData];
    NSArray *indexPathsToInsert = [self indexPathsOfArray:updatedData notInArray:previousData];
    
    [tableView beginUpdates];
    [tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView endUpdates];
}

- (void)showNote:(HPNote*)note
{
    HPNoteViewController *noteViewController = [[HPNoteViewController alloc] init];
    noteViewController.note = note;
    [self.navigationController pushViewController:noteViewController animated:YES];
}

- (NSArray*)notesWithSearchString:(NSString*)searchString
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.text contains[cd] %@", searchString];
    return [_notes filteredArrayUsingPredicate:predicate];
}

- (NSArray*)indexPathsOfArray:(NSArray*)objectsA notInArray:(NSArray*)objectsB
{ // TODO: Profile performance with many objects. Can this be done in O(n+m) with dictionaries?
    NSInteger countA = objectsA.count;
    NSInteger countB = objectsB.count;
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSInteger i = 0, j = 0; i < countA; i++)
    {
        if (j >= countB)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [indexPaths addObject:indexPath];
            continue;
        }
        
        id objectA = objectsA[i];
        
        BOOL found = NO;
        for (NSInteger k = j; k < countB; k++)
        {
            id objectB = objectsB[k];
            if (objectA == objectB)
            {
                j++;
                found = YES;
                break;
            }
        }
        
        if (!found)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [indexPaths addObject:indexPath];
        }
    }
    return indexPaths;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *objects = self.searchDisplayController.searchResultsTableView == tableView ? _searchResults : _notes;
    return objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HPNoteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSArray *objects = self.searchDisplayController.searchResultsTableView == tableView ? _searchResults : _notes;
    HPNote *note = [objects objectAtIndex:indexPath.row];
    cell.note = note;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *objects = self.searchDisplayController.searchResultsTableView == tableView ? _searchResults : _notes;
    HPNote *note = [objects objectAtIndex:indexPath.row];
    [self showNote:note];
}

#pragma mark - UISearchDisplayDelegate

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    // TODO: Track
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    [tableView registerClass:[HPNoteTableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    _searchString = searchString;
    _searchResults = [self notesWithSearchString:searchString];
    return YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller willShowSearchResultsTableView:(UITableView *)tableView
{
    _searching = YES;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didHideSearchResultsTableView:(UITableView *)tableView
{
    _searching = NO;
}

@end
