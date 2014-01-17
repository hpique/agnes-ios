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
    NSMutableArray *_notes;
    
    BOOL _searching;
    NSString *_searchString;
    NSArray *_searchResults;
    
    IBOutlet UIView *_titleView;
    __weak IBOutlet UILabel *_displayCriteriaLabel;
    __weak IBOutlet UILabel *_titleLabel;
    
    HPNoteDisplayCriteria _displayCriteria;
    BOOL _userChangedDisplayCriteria;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"All Notes", @"");
    
    UIBarButtonItem *addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    self.navigationItem.rightBarButtonItem = addNoteBarButtonItem;
    [_tableView registerClass:[HPNoteTableViewCell class] forCellReuseIdentifier:@"cell"];
    _tableView.editing = YES;
    
    self.navigationItem.titleView = _titleView;
    _titleLabel.text = self.title;
    
    _displayCriteria = HPNoteDisplayCriteriaOrder;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNotes:animated]; // TODO: This should be triggered by a notification from the note manager.
}

- (void)updateNotes:(BOOL)animated
{
    _tableView.editing = _displayCriteria == HPNoteDisplayCriteriaOrder;
    
    NSArray *previousNotes = _notes;
    NSArray *notes = [[HPNoteManager sharedManager] sortedNotesWithCriteria:_displayCriteria];
    _notes = [NSMutableArray arrayWithArray:notes];
    NSString *criteriaDescription = [self descriptionForDisplayCriteria:_displayCriteria];
    
    if (animated)
    {
        // For some reason the following doesn't work
        /* [UIView animateWithDuration:0.2 animations:^{
            _displayCriteriaLabel.text = criteriaDescription;
        }]; */
        
        CATransition *animation = [CATransition animation];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.type = kCATransitionFade;
        animation.duration = 0.2;
        [_titleView.layer addAnimation:animation forKey:nil];
        
        _displayCriteriaLabel.text = criteriaDescription;
        
        [self updateTableView:_tableView previousData:previousNotes updatedData:_notes];
    }
    else
    {
        _displayCriteriaLabel.text = criteriaDescription;
        [_tableView reloadData];
    }
    if (!_searching || _searchString == nil) return;

    UITableView *searchTableView = self.searchDisplayController.searchResultsTableView;
    NSArray *previousSearchResults = _searchResults;
    _searchResults = [self notesWithSearchString:_searchString];
    if (animated)
    {
        [self updateTableView:searchTableView previousData:previousSearchResults updatedData:_searchResults];
    }
    else
    {
        [searchTableView reloadData];
    }
}

#pragma mark - Actions

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self showNote:nil];
}

- (IBAction)tapTitleView:(id)sender
{
    _userChangedDisplayCriteria = YES;
    static NSArray *values;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        values = @[@(HPNoteDisplayCriteriaOrder), @(HPNoteDisplayCriteriaModifiedAt), @(HPNoteDisplayCriteriaAlphabetical), @(HPNoteDisplayCriteriaViews)];
    });
    
    NSInteger index = [values indexOfObject:@(_displayCriteria)];
    index = (index + 1) % values.count;
    _displayCriteria = [values[index] intValue];
    [self updateNotes:YES /* animated */];
}

#pragma mark - Private

- (void)updateTableView:(UITableView*)tableView previousData:(NSArray*)previousData updatedData:(NSArray*)updatedData
{
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    [previousData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         // TODO: Use dictionaries
         if (![updatedData containsObject:obj])
         {
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
             [indexPathsToDelete addObject:indexPath];
         }
     }];

    [tableView beginUpdates];
    [tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    [updatedData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         // TODO: Use dictionaries
         NSUInteger previousIndex = [previousData indexOfObject:obj];
         if (previousIndex == NSNotFound)
         {
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:0];
             [indexPathsToInsert addObject:indexPath];
         }
         else if (previousIndex != idx)
         {
             NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:previousIndex inSection:0];
             NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:idx inSection:0];
             [tableView moveRowAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
         }
     }];
    [tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
    [tableView endUpdates];
}

- (void)showNote:(HPNote*)note
{
    HPNoteViewController *noteViewController = [[HPNoteViewController alloc] init];
    noteViewController.note = note;
    [self.navigationController pushViewController:noteViewController animated:YES];
}

- (NSString*)descriptionForDisplayCriteria:(HPNoteDisplayCriteria)criteria
{
    switch (criteria)
    {
        case HPNoteDisplayCriteriaOrder: return _userChangedDisplayCriteria ? NSLocalizedString(@"custom", @"") : @"";
        case HPNoteDisplayCriteriaAlphabetical: return NSLocalizedString(@"a-z", @"");
        case HPNoteDisplayCriteriaModifiedAt: return NSLocalizedString(@"by date", @"");
        case HPNoteDisplayCriteriaViews: return NSLocalizedString(@"most viewed", @"");
    }
}

- (NSArray*)notesWithSearchString:(NSString*)searchString
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.text contains[cd] %@", searchString];
    return [_notes filteredArrayUsingPredicate:predicate];
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

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _displayCriteria == HPNoteDisplayCriteriaOrder;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSInteger index = sourceIndexPath.row;
    id object = _notes[index];
    [_notes removeObjectAtIndex:sourceIndexPath.row];
    [_notes insertObject:object atIndex:destinationIndexPath.row];
    
    NSInteger notesCount = _notes.count;
    for (NSInteger i = 0; i < notesCount; i++)
    {
        HPNote *note = _notes[i];
        note.order = notesCount - i;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *objects = self.searchDisplayController.searchResultsTableView == tableView ? _searchResults : _notes;
    HPNote *note = [objects objectAtIndex:indexPath.row];
    [self showNote:note];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
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
