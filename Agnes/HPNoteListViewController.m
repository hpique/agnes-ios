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
#import "HPNoteListTableViewCell.h"
#import "HPNoteSearchTableViewCell.h"
#import "HPIndexItem.h"
#import "MMDrawerController.h"
#import "MMDrawerBarButtonItem.h"
#import "UIViewController+MMDrawerController.h"
#import "HPPreferencesManager.h"

@interface HPNoteListViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation HPNoteListViewController {
    __weak IBOutlet UITableView *_tableView;
    NSMutableArray *_notes;
    
    BOOL _searching;
    NSString *_searchString;
    NSArray *_searchResults;
    NSArray *_archivedSearchResults;
    
    IBOutlet UIView *_titleView;
    __weak IBOutlet UILabel *_displayCriteriaLabel;
    __weak IBOutlet UILabel *_titleLabel;
    
    HPNoteDisplayCriteria _displayCriteria;
    BOOL _userChangedDisplayCriteria;
    
    UIBarButtonItem *_addNoteBarButtonItem;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    [_tableView registerClass:[HPNoteListTableViewCell class] forCellReuseIdentifier:@"cell"];
    _tableView.editing = YES;
    
    MMDrawerBarButtonItem *drawerBarButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(drawerBarButtonAction:)];
    self.navigationItem.leftBarButtonItem = drawerBarButton;
    
    self.navigationItem.titleView = _titleView;
    
    self.searchDisplayController.searchBar.keyboardType = UIKeyboardTypeTwitter;
    
    [_tableView setContentOffset:CGPointMake(0,self.searchDisplayController.searchBar.frame.size.height) animated:YES]; // TODO: Use autolayout?

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];

    [self updateNotes:NO /* animated */];
    [self updateIndexItem];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self updateNotes:animated];
}

#pragma mark - Public

- (void)setIndexItem:(HPIndexItem *)indexItem
{
    _indexItem = indexItem;
    [self updateIndexItem];
}

+ (UIViewController*)controllerWithIndexItem:(HPIndexItem*)indexItem
{
    HPNoteListViewController *noteListViewController = [[HPNoteListViewController alloc] init];
    noteListViewController.indexItem = indexItem;
    UINavigationController *controller = [[UINavigationController alloc] initWithRootViewController:noteListViewController];
    return controller;
}

#pragma mark - Actions

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    HPNoteViewController *noteViewController = [HPNoteViewController blankNoteViewControllerWithNotes:_notes indexItem:self.indexItem];
    [self.navigationController pushViewController:noteViewController animated:YES];
}

- (void)archiveNoteInCell:(HPNoteListTableViewCell*)cell
{
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    [_notes removeObjectAtIndex:indexPath.row];
    [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [[HPNoteManager sharedManager] archiveNote:cell.note];
}

- (void)unarchiveNoteInCell:(HPNoteListTableViewCell*)cell
{
    NSIndexPath *indexPath = [_tableView indexPathForCell:cell];
    [_notes removeObjectAtIndex:indexPath.row];
    [_tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [[HPNoteManager sharedManager] unarchiveNote:cell.note];
}

- (void)notesDidChangeNotification:(NSNotification*)notification
{
    [self updateNotes:YES /* animated */];
}

- (void)drawerBarButtonAction:(MMDrawerBarButtonItem*)barButtonItem
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (IBAction)tapTitleView:(id)sender
{
    _userChangedDisplayCriteria = YES;
    NSArray *values = self.indexItem.allowedDisplayCriteria;
    NSInteger index = [values indexOfObject:@(_displayCriteria)];
    index = (index + 1) % values.count;
    _displayCriteria = [values[index] intValue];
    [[HPPreferencesManager sharedManager] setDisplayCriteria:_displayCriteria forListTitle:self.indexItem.title];
    [self updateNotes:YES /* animated */];
    [self updateDisplayCriteria:NO /* animated */];
}

#pragma mark - Private

- (void)updateNotes:(BOOL)animated
{
    NSArray *previousNotes = _notes;
    NSArray *notes = self.indexItem.notes;
    notes = [HPNoteManager sortedNotes:notes criteria:_displayCriteria tag:self.indexItem.tag];
    _notes = [NSMutableArray arrayWithArray:notes];
    
    if (animated)
    {
        [self updateTableView:_tableView previousData:previousNotes updatedData:_notes section:0];
    }
    else
    {
        [_tableView reloadData];
    }
    if (!_searching || _searchString == nil) return;
    
    UITableView *searchTableView = self.searchDisplayController.searchResultsTableView;
    if (animated)
    {
        NSArray *previousSearchResults = _searchResults;
        _searchResults = [self notesWithSearchString:_searchString archived:NO];
        [self updateTableView:searchTableView previousData:previousSearchResults updatedData:_searchResults section:0];
        
        NSArray *previousArchivedSearchResults = _archivedSearchResults;
        _archivedSearchResults = [self notesWithSearchString:_searchString archived:YES];
        [self updateTableView:searchTableView previousData:previousArchivedSearchResults updatedData:_archivedSearchResults section:1];
    }
    else
    {
        [searchTableView reloadData];
    }
}

- (void)updateIndexItem
{
    self.title = self.indexItem.title;
    _titleLabel.text = self.title;
    
    self.navigationItem.rightBarButtonItem = self.indexItem.disableAdd ? nil : _addNoteBarButtonItem;
    _displayCriteria = [[HPPreferencesManager sharedManager] displayCriteriaForListTitle:self.indexItem.title default:self.indexItem.defaultDisplayCriteria];
    [self updateDisplayCriteria:NO /* animated */];
}

- (void)updateDisplayCriteria:(BOOL)animated
{
    _tableView.editing = _displayCriteria == HPNoteDisplayCriteriaOrder;
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
        
    }
    _displayCriteriaLabel.text = criteriaDescription;
    
    [_tableView.visibleCells enumerateObjectsUsingBlock:^(HPNoteListTableViewCell *cell, NSUInteger idx, BOOL *stop) {
        cell.displayCriteria = _displayCriteria;
    }];
}

- (void)updateTableView:(UITableView*)tableView previousData:(NSArray*)previousData updatedData:(NSArray*)updatedData section:(NSUInteger)section
{
    if (!previousData)
    {
        [tableView reloadData];
        return;
    }
    
    NSMutableArray *indexPathsToDelete = [NSMutableArray array];
    [previousData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         // TODO: Use dictionaries
         if (![updatedData containsObject:obj])
         {
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:section];
             [indexPathsToDelete addObject:indexPath];
         }
     }];

    NSMutableArray *indexPathsToInsert = [NSMutableArray array];
    NSMutableArray *indexPathsToMove = [NSMutableArray array];
    [updatedData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop)
     {
         // TODO: Use dictionaries
         NSUInteger previousIndex = [previousData indexOfObject:obj];
         if (previousIndex == NSNotFound)
         {
             NSIndexPath *indexPath = [NSIndexPath indexPathForRow:idx inSection:section];
             [indexPathsToInsert addObject:indexPath];
         }
         else if (previousIndex != idx)
         {
             NSIndexPath *fromIndexPath = [NSIndexPath indexPathForRow:previousIndex inSection:section];
             NSIndexPath *toIndexPath = [NSIndexPath indexPathForRow:idx inSection:section];
             [indexPathsToMove addObject:@[fromIndexPath, toIndexPath]];
         }
     }];
    
    if (indexPathsToDelete.count > 0 || indexPathsToMove.count > 0 || indexPathsToInsert.count > 0)
    {
        [tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
        for (NSArray *indexPaths in indexPathsToMove)
        {
            [tableView moveRowAtIndexPath:indexPaths[0] toIndexPath:indexPaths[1]];
        }
        [tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
    }
}

- (void)showNote:(HPNote*)note in:(NSArray*)notes
{
    HPNoteViewController *noteViewController = [HPNoteViewController noteViewControllerWithNote:note notes:_notes indexItem:self.indexItem];
    [self.navigationController pushViewController:noteViewController animated:YES];
}

- (NSString*)descriptionForDisplayCriteria:(HPNoteDisplayCriteria)criteria
{
    if (!_userChangedDisplayCriteria) return @"";
    switch (criteria)
    {
        case HPNoteDisplayCriteriaOrder: return NSLocalizedString(@"custom", @"");
        case HPNoteDisplayCriteriaAlphabetical: return NSLocalizedString(@"a-z", @"");
        case HPNoteDisplayCriteriaModifiedAt: return NSLocalizedString(@"by date", @"");
        case HPNoteDisplayCriteriaViews: return NSLocalizedString(@"most viewed", @"");
    }
}

- (NSArray*)notesWithSearchString:(NSString*)searchString archived:(BOOL)archived
{
    // TODO: Move to HPNoteManager
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.%@ contains[cd] %@ && SELF.%@ == %d",
                              NSStringFromSelector(@selector(text)),
                              searchString,
                              NSStringFromSelector(@selector(archived)),
                              archived ? 1 : 0];
    NSArray *unfilteredNotes = archived ? [HPNoteManager sharedManager].objects : _notes;
    NSArray *filteredNotes = [unfilteredNotes filteredArrayUsingPredicate:predicate];
    NSArray *rankedNotes = [filteredNotes sortedArrayUsingComparator:^NSComparisonResult(HPNote *obj1, HPNote *obj2)
    {
        NSComparisonResult result = HPCompareSearchResults(obj1.title, obj2.title, searchString);
        if (result != NSOrderedSame) return result;
        result = HPCompareSearchResults(obj1.body, obj2.body, searchString);
        if (result != NSOrderedSame) return result;
        return [obj1.modifiedAt compare:obj2.modifiedAt];
    }];
    return rankedNotes;
}

NSComparisonResult HPCompareSearchResults(NSString *text1, NSString *text2, NSString *search)
{
    NSRange range1 = [text1 rangeOfString:search options:NSCaseInsensitiveSearch];
    NSRange range2 = [text2 rangeOfString:search options:NSCaseInsensitiveSearch];
    NSUInteger location1 = range1.location == NSNotFound ? NSUIntegerMax : range1.location;
    NSUInteger location2 = range2.location == NSNotFound ? NSUIntegerMax : range2.location;
    if (location1 < location2) return NSOrderedAscending;
    if (location1 > location2) return NSOrderedDescending;
    return NSOrderedSame;
}

- (NSArray*)tableView:(UITableView*)tableView notesInSection:(NSInteger)section
{
    NSArray *notes = self.searchDisplayController.searchResultsTableView == tableView ? (section == 0 ? _searchResults : _archivedSearchResults) : _notes;
    return notes;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.searchDisplayController.searchResultsTableView == tableView ? (_archivedSearchResults.count > 0 ? 2 : 1) : 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == 1 ? NSLocalizedString(@"Archived", @"") : nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *objects = [self tableView:tableView notesInSection:section];
    return objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSArray *objects = [self tableView:tableView notesInSection:indexPath.section];
    if (self.searchDisplayController.searchResultsTableView == tableView)
    {
        HPNoteSearchTableViewCell *searchCell = (HPNoteSearchTableViewCell*)cell;
        HPNote *note = [objects objectAtIndex:indexPath.row];
        searchCell.searchText = _searchString;
        searchCell.note = note;
    }
    else
    {
        HPNoteListTableViewCell *noteCell = (HPNoteListTableViewCell*)cell;
        HPNote *note = [objects objectAtIndex:indexPath.row];
        noteCell.note = note;
        noteCell.displayCriteria = _displayCriteria;
        noteCell.separatorInset = UIEdgeInsetsZero;

        
        UIView *swipeView = [[UIView alloc] init];
        if (note.archived)
        {
            __weak id weakNoteCell = noteCell;
            [noteCell setSwipeGestureWithView:swipeView color:[UIColor greenColor] mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode)
             {
                 [self unarchiveNoteInCell:weakNoteCell];
             }];
        } else {
            __weak id weakNoteCell = noteCell;
            [noteCell setSwipeGestureWithView:swipeView color:[UIColor redColor] mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode)
             {
                 [self archiveNoteInCell:weakNoteCell];
             }];
        }
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchDisplayController.searchResultsTableView == tableView) return NO;
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
        [note setOrder:notesCount - i inTag:self.indexItem.tag];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *objects = [self tableView:tableView notesInSection:indexPath.section];
    HPNote *note = [objects objectAtIndex:indexPath.row];
    [self showNote:note in:objects];
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
    [tableView registerClass:[HPNoteSearchTableViewCell class] forCellReuseIdentifier:@"cell"];
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    _searchString = searchString;
    _searchResults = [self notesWithSearchString:searchString archived:NO];
    _archivedSearchResults = [self notesWithSearchString:searchString archived:YES];
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
