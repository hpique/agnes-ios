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
#import "HPPreferencesManager.h"
#import "HPNoteExporter.h"
#import "HPReorderTableView.h"
#import "MMDrawerController.h"
#import "MMDrawerBarButtonItem.h"
#import "UIViewController+MMDrawerController.h"
#import "UIColor+iOS7Colors.h"
#import <MessageUI/MessageUI.h>
#import "HPNoteListDetailTransitionAnimator.h"

static NSString* HPNoteListTableViewCellReuseIdentifier = @"Cell";

@interface HPNoteListViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate>

@end

@implementation HPNoteListViewController {
    __weak IBOutlet HPReorderTableView *_notesTableView;
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
    
    IBOutlet UIView *_footerView;
    HPNoteExporter *_noteExporter;
    
    NSInteger _optionsActionSheetUndoIndex;
    NSInteger _optionsActionSheetRedoIndex;
    NSInteger _optionsActionSheetExportIndex;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
}

//- (void)updateFooterView
//{
//    CGRect frame = _tableView.frame;
//    CGSize contentSize = _tableView.contentSize;
//    CGFloat height = frame.size.height - contentSize.height;
//    if (height > 72)
//    {
//        CGRect footerFrame = _footerView.frame;
//        _footerView.frame = CGRectMake(footerFrame.origin.x, footerFrame.origin.y, footerFrame.size.width, height);
//    }
//    //    _tableView.tableFooterView = _footerView;
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    UINib *nib = [UINib nibWithNibName:@"HPNoteListTableViewCell" bundle:nil];
    [_notesTableView registerNib:nib forCellReuseIdentifier:HPNoteListTableViewCellReuseIdentifier];
    _notesTableView.tableFooterView = _footerView;
    _notesTableView.delegate = self;
    
    MMDrawerBarButtonItem *drawerBarButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(drawerBarButtonAction:)];
    self.navigationItem.leftBarButtonItem = drawerBarButton;
    
    self.navigationItem.titleView = _titleView;
    
    self.searchDisplayController.searchBar.keyboardType = UIKeyboardTypeTwitter;
    
    [_notesTableView setContentOffset:CGPointMake(0,self.searchDisplayController.searchBar.frame.size.height) animated:YES]; // TODO: Use autolayout?

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];

    [self updateNotes:NO /* animated */];
    [self updateIndexItem];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // [_notesTableView deselectRowAtIndexPath:[_notesTableView indexPathForSelectedRow] animated:animated]; // Do not deselect the selected row of the animator will not know where to return
    [self updateNotes:animated];
}

#pragma mark - Public

- (BOOL)selectNote:(HPNote*)note
{
    NSIndexPath *indexPath = [self indexPathOfNote:note];
    if (!indexPath) return NO;
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
    return YES;
}

- (void)setIndexItem:(HPIndexItem *)indexItem
{
    _indexItem = indexItem;
    [self updateIndexItem];
}

- (UITableView*)tableView
{
    return _searching ? self.searchDisplayController.searchResultsTableView : _notesTableView;
}

+ (UINavigationController*)controllerWithIndexItem:(HPIndexItem*)indexItem
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
    NSIndexPath *indexPath = [_notesTableView indexPathForCell:cell];
    [_notes removeObjectAtIndex:indexPath.row];
    [_notesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [[HPNoteManager sharedManager] archiveNote:cell.note];
}

- (void)exportNotes
{
    _noteExporter = [[HPNoteExporter alloc] init];
    [_noteExporter exportNotes:_notes name:self.indexItem.exportPrefix success:^(NSURL *fileURL) {
        [self exportFileURL:fileURL];
    } failure:^(NSError *error) {
        NSString *message = error ? [error localizedDescription] : NSLocalizedString(@"Unknown error", @"");
        [self alertErrorWithTitle:NSLocalizedString(@"Export Failed", @"") message:message];
        _noteExporter = nil;
    }];
}

- (void)unarchiveNoteInCell:(HPNoteListTableViewCell*)cell
{
    NSIndexPath *indexPath = [_notesTableView indexPathForCell:cell];
    [_notes removeObjectAtIndex:indexPath.row];
    [_notesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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

- (IBAction)optionsButtonAction:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;
    NSUndoManager *undoManager = [HPNoteManager sharedManager].context.undoManager;
    _optionsActionSheetUndoIndex = -1;
    if ([undoManager canUndo])
    {
        _optionsActionSheetUndoIndex = [actionSheet addButtonWithTitle:[undoManager undoMenuItemTitle]];
    }
    
    _optionsActionSheetRedoIndex = -1;
    if ([undoManager canRedo])
    {
        _optionsActionSheetRedoIndex = [actionSheet addButtonWithTitle:[undoManager redoMenuItemTitle]];
    }
    
    _optionsActionSheetExportIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Export", @"")];
    NSInteger cancelIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
    actionSheet.cancelButtonIndex = cancelIndex;
    [actionSheet showInView:self.view];
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

- (void)alertErrorWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alertView show];
}

- (void)exportFileURL:(NSURL*)fileURL
{
    if ([MFMailComposeViewController canSendMail])
    {
        NSData *data = [NSData dataWithContentsOfURL:fileURL];
        if (data)
        {
            MFMailComposeViewController *vc = [[MFMailComposeViewController alloc] init];
            vc.mailComposeDelegate = self;
            NSString *subject = [NSString stringWithFormat:NSLocalizedString(@"Agnes %@ export", @""), self.indexItem.title];
            [vc setSubject:subject];
            [vc addAttachmentData:data mimeType:@"application/zip" fileName:@"notes.zip"];
            [self presentViewController:vc animated:YES completion:nil];
        }
        else
        {
            [self alertErrorWithTitle:NSLocalizedString(@"Export Failed", @"") message:NSLocalizedString(@"Unable to read zip file", @"")];
        }
    }
    else if ([[UIApplication sharedApplication] canOpenURL:fileURL])
    {
        UIDocumentInteractionController *documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
        [documentController presentOpenInMenuFromRect:CGRectZero inView:self.view animated:YES];
    }
    else
    {
        [self alertErrorWithTitle:NSLocalizedString(@"Export Failed", @"") message:NSLocalizedString(@"A functioning email client is required", @"")];
    }
    _noteExporter = nil;
}

- (NSIndexPath*)indexPathOfNote:(HPNote*)note
{
    if (self.tableView == _notesTableView)
    {
        NSUInteger row = [_notes indexOfObject:note];
        return row == NSNotFound ? nil : [NSIndexPath indexPathForRow:row inSection:0];
    }
    else
    {
        NSUInteger row = [_searchResults indexOfObject:note];
        if (row != NSNotFound) return [NSIndexPath indexPathForRow:row inSection:0];
        row = [_archivedSearchResults indexOfObject:note];
        if (row != NSNotFound) return [NSIndexPath indexPathForRow:row inSection:1];
    }
    return nil;
}

- (void)updateNotes:(BOOL)animated
{
    NSArray *previousNotes = _notes;
    NSArray *notes = self.indexItem.notes;
    notes = [HPNoteManager sortedNotes:notes criteria:_displayCriteria tag:self.indexItem.tag];
    _notes = [NSMutableArray arrayWithArray:notes];
    
    if (animated)
    {
        [self updateTableView:_notesTableView previousData:previousNotes updatedData:_notes section:0];
    }
    else
    {
        [_notesTableView reloadData];
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
    
    [_notesTableView.visibleCells enumerateObjectsUsingBlock:^(HPNoteListTableViewCell *cell, NSUInteger idx, BOOL *stop) {
        [cell setDisplayCriteria:_displayCriteria animated:animated];
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
    noteViewController.showDetail = _displayCriteria == HPNoteDisplayCriteriaModifiedAt;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HPNoteListTableViewCellReuseIdentifier];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
        [noteCell setDisplayCriteria:_displayCriteria animated:NO];
        noteCell.separatorInset = UIEdgeInsetsZero;

        noteCell.shouldAnimateIcons = NO;
        
        if (note.archived)
        {
            UIImageView *swipeView = [self swipeViewWithImageNamed:@"icon-inbox"];
            swipeView.center = CGPointMake(swipeView.center.x + 20, swipeView.center.y);
            __weak id weakNoteCell = noteCell;
            [noteCell setSwipeGestureWithView:swipeView color:[UIColor iOS7greenColor] mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode)
             {
                 swipeView.image = [[UIImage imageNamed:@"icon-checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                     [self unarchiveNoteInCell:weakNoteCell];
                 });
             }];
        } else {
             UIImageView *swipeView = [self swipeViewWithImageNamed:@"icon-archive"];
            swipeView.center = CGPointMake(swipeView.center.x - 20, swipeView.center.y);
            __weak id weakNoteCell = noteCell;
            [noteCell setSwipeGestureWithView:swipeView color:[UIColor iOS7orangeColor] mode:MCSwipeTableViewCellModeExit state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode)
             {
                 swipeView.image = [[UIImage imageNamed:@"icon-checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                 [swipeView sizeToFit];
                 dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
                     [self archiveNoteInCell:weakNoteCell];
                 });
             }];
        }
    }
    return cell;
}

- (UIImageView*)swipeViewWithImageNamed:(NSString*)imageName
{
    UIImage *image = [UIImage imageNamed:imageName];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.tintColor = [UIColor whiteColor];
    return imageView;
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
    
    [[HPNoteManager sharedManager] reorderNotes:_notes tagName:self.indexItem.tag];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *objects = [self tableView:tableView notesInSection:indexPath.section];
    HPNote *note = [objects objectAtIndex:indexPath.row];
    [self showNote:note in:objects];
}

#pragma mark - UISearchDisplayDelegate

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    // TODO: Track
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    UINib *nib = [UINib nibWithNibName:@"HPNoteSearchTableViewCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:HPNoteListTableViewCellReuseIdentifier];
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

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == _optionsActionSheetExportIndex)
    {
        [self exportNotes];
    }
    else if (buttonIndex == _optionsActionSheetRedoIndex)
    {
        NSUndoManager *undoManager = [HPNoteManager sharedManager].context.undoManager;
        [undoManager redo];
    }
    else if (buttonIndex == _optionsActionSheetUndoIndex)
    {
        NSUndoManager *undoManager = [HPNoteManager sharedManager].context.undoManager;
        [undoManager undo];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == _notesTableView.reorderGestureRecognizer)
    {
        return _displayCriteria == HPNoteDisplayCriteriaOrder;
    }
    return NO;
}


@end
