//
//  AGNNoteListViewController.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "AGNNoteListViewController.h"
#import "AGNListDataSource.h"
#import "AGNSearchDataSource.h"
#import "AGNNoteViewController.h"
#import "AGNUIMetrics.h"
#import "HPNoteManager.h"
#import "HPTagManager.h"
#import "HPNote.h"
#import "HPTracker.h"
#import "HPNoteListTableViewCell.h"
#import "HPNoteSearchTableViewCell.h"
#import "HPIndexItem.h"
#import "AGNPreferencesManager.h"
#import "HPNoteImporter.h"
#import "HPReorderTableView.h"
#import "HPNoteListDetailTransitionAnimator.h"
#import "HPNoteNavigationController.h"
#import "HPNoteListSearchBar.h"
#import "HPFontManager.h"
#import "HPNavigationBarToggleTitleView.h"
#import "AGNModelManager.h"
#import "UITableView+hp_reloadChanges.h"
#import "UIImage+hp_utils.h"
#import "NSNotification+hp_status.h"
#import "UIViewController+MMDrawerController.h"
#import <iOS7Colors/UIColor+iOS7Colors.h>
#import "UIColor+hp_utils.h"

static NSString* AGNNoteListTableViewCellReuseIdentifier = @"Cell";

@interface AGNNoteListViewController () <UITableViewDelegate, AGNListDataSourceDelegate, HPSectionArrayDataSourceDelegate, UIGestureRecognizerDelegate, AGNNoteViewControllerDelegate, UISearchDisplayDelegate>

@end

@implementation AGNNoteListViewController {
    __weak IBOutlet HPReorderTableView *_notesTableView;
    IBOutlet AGNListDataSource *_listDataSource;
    
    BOOL _searching;
    NSString *_searchString;
    __weak IBOutlet UISearchBar *_searchBar;
    IBOutlet AGNSearchDataSource *_searchDataSource;
    
    IBOutlet HPNavigationBarToggleTitleView *_titleView;
    
    HPTagSortMode _sortMode;
    BOOL _userChangedSortMode;
    
    UIBarButtonItem *_addNoteBarButtonItem;
    
    __weak IBOutlet UIView *_emptyListView;
    __weak IBOutlet UILabel *_emptyTitleLabel;
    __weak IBOutlet UILabel *_emptySubtitleLabel;
    __weak IBOutlet NSLayoutConstraint *_emptyCenterYTitleLabelLayoutConstraint;
    
    NSIndexPath *_indexPathOfSelectedNote;
    BOOL _ignoreNotesDidChangeNotification;
    BOOL _visible;
    NSMutableSet *_pendingUpdatedNotes;
}

@synthesize indexPathOfSelectedNote = _indexPathOfSelectedNote;
@synthesize transitioning = _transitioning;
@synthesize wantsDefaultTransition = _wantsDefaultTransition;

- (id)initWithIndexItem:(HPIndexItem*)indexItem
{
    self = [super initWithNibName:nil bundle:nil];
    if (self)
    {
        _indexItem = indexItem;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexItemDidChangeNotification:) name:HPIndexItemDidChangeNotification object:_indexItem];
    }
    return self;
}

- (void)dealloc
{
    [self stopObserving];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPIndexItemDidChangeNotification object:_indexItem];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _pendingUpdatedNotes = [NSMutableSet set];
    
    {
        _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"icon-plus"] style:UIBarButtonItemStylePlain target:self action:@selector(addNoteBarButtonItemAction:)];
        self.navigationItem.titleView = _titleView;
        self.navigationItem.rightBarButtonItems = @[_addNoteBarButtonItem];
    }
   
    
    UINib *nib = [UINib nibWithNibName:@"HPNoteListTableViewCell" bundle:nil];
    [_notesTableView registerNib:nib forCellReuseIdentifier:AGNNoteListTableViewCellReuseIdentifier];
    _notesTableView.delegate = self;
    [_notesTableView setContentOffset:CGPointMake(0,self.searchDisplayController.searchBar.frame.size.height) animated:NO];
    _notesTableView.tableFooterView = [UIView new]; // Removes separators of empty cells
    _listDataSource.cellIdentifier = AGNNoteListTableViewCellReuseIdentifier;
    _searchDataSource.cellIdentifier = AGNNoteListTableViewCellReuseIdentifier;
    
    {
        _searchBar.keyboardType = UIKeyboardTypeTwitter;
        // HACK: Using white color below shows black hairline. WTF?
        [_searchBar setBackgroundImage:[UIImage hp_imageWithColor:[UIColor clearColor] size:CGSizeMake(1, 1)] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault]; // HACK: See: http://stackoverflow.com/questions/19927542/ios7-backgroundimage-for-uisearchbar
        UIColor *searchFieldBackgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        UIImage *searchFieldBackgroundImage = [[UIImage hp_imageWithColor:searchFieldBackgroundColor size:CGSizeMake(100, 28)] hp_imageByRoundingCornersWithRadius:4];
        [_searchBar setSearchFieldBackgroundImage:searchFieldBackgroundImage forState:UIControlStateNormal];
        _searchBar.autocorrectionType = UITextAutocorrectionTypeNo; // HACK: See: http://stackoverflow.com/questions/8608529/autocorrect-in-uisearchbar-interferes-when-i-hit-didselectrowatindexpath
    }
    
    [self applyFonts];
    [self applyPreferences];
    
    [self reloadNotesAnimated:NO];
    [self updateIndexItem];
    [self startObserving];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _visible = YES;
    if (self.indexItem)
    {
        [[HPTracker defaultTracker] trackScreenWithName:self.indexItem.listScreenName];
    }
    if (self.searchDisplayController.isActive)
    {
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];        
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.transitioning)
    {
        [self reloadNotesAnimated:animated];
    }
    self.transitioning = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.transitioning = NO;
    _visible = NO;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [_titleView setTitle:self.title];
    [HPNoteTableViewCell invalidateHeightCache];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    const CGFloat inset = [AGNUIMetrics sideMarginForInterfaceOrientation:self.interfaceOrientation width:self.view.bounds.size.width];
    const UIEdgeInsets insets = UIEdgeInsetsMake(0, inset, 0, inset);
    _notesTableView.separatorInset = insets;
    self.searchDisplayController.searchResultsTableView.separatorInset = insets;
}

#pragma mark - Public

- (BOOL)selectNote:(HPNote*)note
{
    _indexPathOfSelectedNote = [self indexPathOfNote:note];
    if (!_indexPathOfSelectedNote) return NO;
    [self.tableView selectRowAtIndexPath:_indexPathOfSelectedNote animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.tableView scrollToRowAtIndexPath:_indexPathOfSelectedNote atScrollPosition:UITableViewScrollPositionNone animated:NO];
    return YES;
}

- (void)setIndexItem:(HPIndexItem *)indexItem
{
    [self.searchDisplayController setActive:NO];
    _indexPathOfSelectedNote = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPIndexItemDidChangeNotification object:_indexItem];

    _indexItem = indexItem;
    
    [AGNPreferencesManager sharedManager].lastViewedTagName = indexItem.tag.name;
    [self updateIndexItem];
    [self reloadNotesAnimated:NO];
    _notesTableView.contentOffset = CGPointMake(0, _notesTableView.tableHeaderView.bounds.size.height - _notesTableView.contentInset.top);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(indexItemDidChangeNotification:) name:HPIndexItemDidChangeNotification object:_indexItem];
}

- (void)showBlankNoteAnimated:(BOOL)animated
{
    _indexPathOfSelectedNote = nil;
    AGNNoteViewController *noteViewController = [AGNNoteViewController noteViewControllerWithNote:nil notes:@[] indexItem:self.indexItem];
    noteViewController.delegate = self;
    [self.navigationController pushViewController:noteViewController animated:animated];
}

- (UITableView*)tableView
{
    return _searching ? self.searchDisplayController.searchResultsTableView : _notesTableView;
}

#pragma mark Actions

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"add_note"];
    [self showBlankNoteAnimated:YES];
}

- (void)archiveNoteInCell:(HPNoteListTableViewCell*)cell
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"archive_note"];
    [self removeNoteInCell:cell modelBlock:^{
        [[HPTagManager sharedManager] archiveNote:cell.note];
    }];
}

- (void)trashNoteInCell:(HPNoteListTableViewCell*)cell
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"trash_note"];
    [self removeNoteInCell:cell modelBlock:^{
        [[HPNoteManager sharedManager] trashNote:cell.note];
    }];
}

- (void)unarchiveNoteInCell:(HPNoteListTableViewCell*)cell
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"unarchive_note"];
    [self removeNoteInCell:cell modelBlock:^{
        [[HPTagManager sharedManager] unarchiveNote:cell.note];
    }];
}

- (IBAction)tapTitleView:(id)sender
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"toggle_sort"];
    _userChangedSortMode = YES;
    NSArray *values = self.indexItem.allowedSortModes;
    NSInteger index = [values indexOfObject:@(_sortMode)];
    index = (index + 1) % values.count;
    _sortMode = [values[index] intValue];
    self.indexItem.sortMode = _sortMode; // Triggers a HPIndexItemDidChangeNotification that causes a reload
    [self updateSortMode:YES /* animated */];
}

#pragma mark - Private

- (void)applyFonts
{
    HPFontManager *fonts = [HPFontManager sharedManager];
    [[UITextField appearanceWhenContainedIn:[HPNoteListSearchBar class], nil] setFont:fonts.fontForSearchBar];
}

- (void)applyPreferences
{
    AGNPreferencesManager *preferences = [AGNPreferencesManager sharedManager];
    [preferences styleSearchBar];
    UITableViewCellSeparatorStyle separatorStyle = preferences.listSeparatorsHidden ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;
    _notesTableView.separatorStyle = separatorStyle;
    self.searchDisplayController.searchResultsTableView.separatorStyle = separatorStyle;
}

- (void)changeModel:(void (^)())modelBlock changeView:(void (^)())viewBlock
{
    _ignoreNotesDidChangeNotification = YES;
    modelBlock();
    viewBlock();
    _ignoreNotesDidChangeNotification = NO;
}

- (NSIndexPath*)indexPathOfNote:(HPNote*)note
{
    if (self.tableView == _notesTableView)
    {
        NSUInteger row = [_listDataSource indexOfItem:note];
        return row == NSNotFound ? nil : [NSIndexPath indexPathForRow:row inSection:0];
    }
    else
    {
        return [_searchDataSource indexPathOfItem:note];
    }
}

- (void)reloadNotesAnimated:(BOOL)animated
{
    [self reloadNotesWithUpdates:[NSSet set] animated:animated];
}

- (void)reloadNotesWithUpdates:(NSSet*)updatedNotes animated:(BOOL)animated
{
    updatedNotes = [updatedNotes setByAddingObjectsFromSet:_pendingUpdatedNotes];
    [_pendingUpdatedNotes removeAllObjects];
    
    NSArray *previousNotes = _listDataSource.items;
    NSArray *notes = self.indexItem.notes;
    _listDataSource.items = notes;
    
    if (animated)
    {
        NSArray *previousData = previousNotes ? @[previousNotes] : nil;
        [_notesTableView hp_reloadChangesWithPreviousData:previousData currentData:@[notes] keyBlock:^id<NSCopying>(HPNote *note) {
            return note.objectID;
        } reloadBlock:^BOOL(HPNote *note) {
            // Only reload remaining notes if the cell height changed
            if (![updatedNotes containsObject:note]) return NO;
            NSInteger index = [previousNotes indexOfObject:note];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            if (![[_notesTableView indexPathsForVisibleRows] containsObject:indexPath]) return NO;
            UITableViewCell *cell = [_notesTableView cellForRowAtIndexPath:indexPath];
            return cell.frame.size.height != [HPNoteTableViewCell heightForNote:note width:cell.frame.size.width tag:self.indexItem.tag];
        }];
    }
    else
    {
        [_notesTableView reloadData];
    }
    
    [self updateEmptyView:animated];
    
    if (!_searching || _searchString == nil) return;
    
    UITableView *searchTableView = self.searchDisplayController.searchResultsTableView;
    if (animated)
    {
        NSArray *previousData = _searchDataSource.sections;
        NSArray *currentData = [_searchDataSource search:_searchString inIndexItem:self.indexItem];
        
        [searchTableView hp_reloadChangesWithPreviousData:previousData
                                              currentData:currentData
                                                 keyBlock:^id<NSCopying>(HPNote *note) {
                                                     return note.objectID;
                                                 } reloadBlock:^BOOL(HPNote *note) {
                                                     return [updatedNotes containsObject:note];
                                                 }];
    }
    else
    {
        [searchTableView reloadData];
    }
}

- (void)removeNoteInCell:(HPNoteListTableViewCell*)cell modelBlock:(void (^)())block
{
    NSIndexPath *indexPath = [_notesTableView indexPathForCell:cell];
    [self changeModel:block changeView:^{
        [_listDataSource removeItemAtIndex:indexPath.row];
        [_notesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        [self updateEmptyView:YES];
    }];
}

- (void)startObserving
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagsDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFontsNotification:) name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willReplaceModelNotification:) name:AGNModelManagerWillReplaceModelNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusNotification:) name:HPStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferences:) name:AGNPreferencesManagerDidChangePreferencesNotification object:[AGNPreferencesManager sharedManager]];
}

- (void)stopObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AGNModelManagerWillReplaceModelNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPStatusNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AGNPreferencesManagerDidChangePreferencesNotification object:[AGNPreferencesManager sharedManager]];
}

- (void)updateEmptyView:(BOOL)animated
{
    BOOL empty = _listDataSource.itemCount == 0;
    if (empty != _emptyListView.hidden) return;

    if (animated)
    {
        _emptyListView.hidden = !empty;
        _emptyListView.alpha = empty ? 0 : 1;
        [UIView animateWithDuration:0.25 animations:^{
            _emptyListView.alpha = empty ? 1 : 0;
        } completion:^(BOOL finished) {
            _emptyListView.hidden = !empty;
        }];
    }
    else
    {
        _emptyListView.hidden = !empty;
    }
}

- (void)updateIndexItem
{
    self.title = self.indexItem.title;
    [_titleView setTitle:self.title];
    _emptyTitleLabel.text = self.indexItem.emptyTitle;
    _emptySubtitleLabel.text = self.indexItem.emptySubtitle;
    _emptyTitleLabel.font = self.indexItem.emptyTitleFont;
    _emptySubtitleLabel.font = self.indexItem.emptySubtitleFont;
    _emptyCenterYTitleLabelLayoutConstraint.constant = [_emptySubtitleLabel intrinsicContentSize].height;
    self.searchDisplayController.searchBar.placeholder = [NSString stringWithFormat:NSLocalizedString(@"Search %@", @""), self.title];
    
    _addNoteBarButtonItem.enabled = !self.indexItem.disableAdd;
    _sortMode = self.indexItem.sortMode;
}

- (void)updateSortMode:(BOOL)animated
{
    NSString *criteriaDescription = [self descriptionForSortMode:_sortMode];
    [_titleView setSubtitle:criteriaDescription animated:animated transient:YES];
    const HPTagSortMode sortMode = _sortMode;
    [_notesTableView.visibleCells enumerateObjectsUsingBlock:^(HPNoteListTableViewCell *cell, NSUInteger idx, BOOL *stop) {
        [cell setDetailMode:sortMode animated:animated];
    }];
    {
        CGPoint contentOffset = CGPointMake(0, _notesTableView.tableHeaderView.bounds.size.height - _notesTableView.contentInset.top);
        [_notesTableView setContentOffset:contentOffset animated:animated];
    }
}

- (void)showNote:(HPNote*)note in:(NSArray*)notes
{
    AGNNoteViewController *noteViewController = [AGNNoteViewController noteViewControllerWithNote:note notes:notes indexItem:self.indexItem];
    noteViewController.delegate = self;
    if (_searchString) noteViewController.search = _searchString;
    [self.navigationController pushViewController:noteViewController animated:YES];
}

- (NSString*)descriptionForSortMode:(HPTagSortMode)criteria
{
    if (!_userChangedSortMode) return @"";
    switch (criteria)
    {
        case HPTagSortModeOrder: return NSLocalizedString(@"manual order", @"");
        case HPTagSortModeAlphabetical: return NSLocalizedString(@"a-z", @"");
        case HPTagSortModeModifiedAt: return NSLocalizedString(@"by date", @"");
        case HPTagSortModeViews: return NSLocalizedString(@"most viewed", @"");
        case HPTagSortModeTag: return NSLocalizedString(@"by tag", @"");
    }
}

- (void)setSwipeActionTo:(HPNoteListTableViewCell*)cell imageNamed:(NSString*)imageName color:(UIColor*)color state:(MCSwipeTableViewCellState)state block:(void (^)(HPNoteListTableViewCell *cell))block
{
    static NSCache *imageCache = nil;
    if (!imageCache)
    {
        imageCache = [[NSCache alloc] init];
    }
    UIImage *image = [imageCache objectForKey:imageName];
    if (!image)
    {
        image = [UIImage imageNamed:imageName];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [imageCache setObject:image forKey:imageName];
    }
    UIImageView *swipeView = nil;
    switch (state) {
        case MCSwipeTableViewCellState1:
        case MCSwipeTableViewCellState2:
        default:
        {
            if (!cell.view1)
            {
                UIImageView *imageView = [[UIImageView alloc] init];
                imageView.tintColor = [UIColor whiteColor];
                cell.view1 = imageView;
            }
            swipeView = (UIImageView*)cell.view1;
            cell.defaultColor1 = color;
        }
            break;
        case MCSwipeTableViewCellState3:
        {
            if (!cell.view3)
            {
                UIImageView *imageView = [[UIImageView alloc] init];
                imageView.tintColor = [UIColor whiteColor];
                cell.view3 = imageView;
            }
            swipeView = (UIImageView*)cell.view3;
            cell.defaultColor3 = color;
        }
            break;
        case MCSwipeTableViewCellState4:
        {
            if (!cell.view4)
            {
                UIImageView *imageView = [[UIImageView alloc] init];
                imageView.tintColor = [UIColor whiteColor];
                cell.view4 = imageView;
            }
            swipeView = (UIImageView*)cell.view4;
        }
            break;
    }
    if (swipeView.image != image)
    {
        swipeView.image = image;
    }
    swipeView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    CGFloat offsetDirection = state == MCSwipeTableViewCellState1 || state == MCSwipeTableViewCellState2 ? 1 : -1;
    swipeView.center = CGPointMake(swipeView.center.x + 20 * offsetDirection, swipeView.center.y);
    __weak id weakCell = cell;
    [cell setSwipeGestureWithView:swipeView color:color mode:MCSwipeTableViewCellModeExit state:state completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode)
     {
         swipeView.image = [[UIImage imageNamed:@"icon-checkmark"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
         [swipeView sizeToFit];
         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void){
             block(weakCell);
         });
     }];
}

#pragma mark HPSectionArrayDataSourceDelegate

- (void)dataSource:(HPSectionArrayDataSource*)dataSource configureCell:(HPNoteSearchTableViewCell *)cell withItem:(HPNote *)note atIndexPath:(NSIndexPath*)indexPath
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.searchText = _searchString;
    [cell setNote:note ofTag:self.indexItem.tag detailMode:_sortMode];
}

#pragma mark AGNListDataSourceDelegate

- (BOOL)canMoveItemsInDataSource:(HPArrayDataSource*)dataSource
{
    if (_sortMode == HPTagSortModeOrder) return YES;
    NSString *criteriaDescription = [self descriptionForSortMode:_sortMode];
    [_titleView setSubtitle:criteriaDescription animated:YES transient:YES];
    return NO;
}

- (void)dataSource:(HPArrayDataSource*)dataSource configureCell:(HPNoteListTableViewCell *)cell withItem:(HPNote *)note atIndex:(NSUInteger)index
{
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    HPNoteListTableViewCell *noteCell = (HPNoteListTableViewCell*)cell;
    noteCell.reuseSwipeViews = YES;
    noteCell.shouldAnimateIcons = NO;
    const BOOL isPhone = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone;
    noteCell.firstTrigger = isPhone ? 1.0f/3.0f : 0.2f;
    noteCell.secondTrigger = isPhone ? 2.0f/3.0f : 0.4f;
    __weak id weakSelf = self;
    
    if (!self.indexItem.disableRemove)
    {
        if (note.archived)
        {
            [self setSwipeActionTo:noteCell imageNamed:@"icon-inbox" color:[UIColor iOS7greenColor] state:MCSwipeTableViewCellState1 block:^(HPNoteListTableViewCell *cell) {
                [weakSelf unarchiveNoteInCell:cell];
            }];
            [self setSwipeActionTo:noteCell imageNamed:@"icon-trash" color:[UIColor iOS7redColor] state:MCSwipeTableViewCellState3 block:^(HPNoteListTableViewCell *cell) {
                [weakSelf trashNoteInCell:cell];
            }];
        }
        else
        {
            [self setSwipeActionTo:noteCell imageNamed:@"icon-archive" color:[UIColor iOS7orangeColor] state:MCSwipeTableViewCellState3 block:^(HPNoteListTableViewCell *cell) {
                [weakSelf archiveNoteInCell:cell];
            }];
            [self setSwipeActionTo:noteCell imageNamed:@"icon-trash" color:[UIColor iOS7redColor] state:MCSwipeTableViewCellState4 block:^(HPNoteListTableViewCell *cell) {
                [weakSelf trashNoteInCell:cell];
            }];
        }
    }
    [cell setNote:note ofTag:self.indexItem.tag detailMode:_sortMode];
}

- (void)dataSource:(HPArrayDataSource*)dataSource willMoveItemAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex
{
    _ignoreNotesDidChangeNotification = YES;
    HPTag *tag = self.indexItem.tag;
    NSArray *notes = _listDataSource.items;
    [[HPNoteManager sharedManager] reorderNotes:notes exchangeObjectAtIndex:sourceIndex withObjectAtIndex:destinationIndex inTag:tag];
}

- (void)dataSource:(HPArrayDataSource*)dataSource didMoveItemAtIndex:(NSUInteger)sourceIndex toIndex:(NSUInteger)destinationIndex
{
    _ignoreNotesDidChangeNotification = NO;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 8 : 0;
        case 1: // Search archived section header
            return 22;
        default:
            return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
     // Don't use default colored header for first header
    return section == 0 ? [UIView new] : nil;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<HPDataSource> dataSource = (id<HPDataSource>) tableView.dataSource;
    HPNote *note = [dataSource itemAtIndexPath:indexPath];
    if ([dataSource itemCount] < 6)
    { // Height will be calculated anyway as all indexPaths will be visible
        return [self tableView:tableView heightForNote:note];
    }
    else
    {
        HPTag *tag = _notesTableView == tableView ? self.indexItem.tag : [HPTagManager sharedManager].inboxTag; // Search doesn't care about tags
        const CGFloat width = tableView.bounds.size.width;
        return [HPNoteTableViewCell estimatedHeightForNote:note width:width inTag:tag];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id<HPDataSource> dataSource = (id<HPDataSource>) tableView.dataSource;
    HPNote *note = [dataSource itemAtIndexPath:indexPath];
    return [self tableView:tableView heightForNote:note];
}

- (CGFloat)tableView:(UITableView *)tableView heightForNote:(HPNote *)note
{
    const CGFloat width = tableView.bounds.size.width;
    if (tableView == _notesTableView)
    {
        HPTag *tag = self.indexItem.tag;
        return [HPNoteTableViewCell heightForNote:note width:width tag:tag];
    }
    else
    {
        return [HPNoteSearchTableViewCell heightForNote:note width:width searchText:_searchString];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _indexPathOfSelectedNote = indexPath;
    id<HPDataSource> dataSource = (id<HPDataSource>) tableView.dataSource;
    HPNote *note = [dataSource itemAtIndexPath:indexPath];
    NSArray *notes = [dataSource itemsAtSection:indexPath.section];
    [self showNote:note in:notes];
}

#pragma mark UISearchDisplayDelegate

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"search"];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
    self.title = NSLocalizedString(@"Search", @"");
    _searching = YES;
    _searchBar.tintColor = [AGNPreferencesManager sharedManager].barForegroundColor;
}

- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    AGNPreferencesManager *preferences = [AGNPreferencesManager sharedManager];
    [[UIApplication sharedApplication] setStatusBarStyle:preferences.statusBarStyle animated:YES];
    _searchBar.translucent = NO;
    _searchBar.tintColor = nil;
}

- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    self.title = self.indexItem.title;
    _searching = NO;
    _searchString = nil;
    _searchDataSource.sections = @[];
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    UINib *nib = [UINib nibWithNibName:@"HPNoteSearchTableViewCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:AGNNoteListTableViewCellReuseIdentifier];
    tableView.separatorStyle = _notesTableView.separatorStyle;
    tableView.separatorColor = _notesTableView.separatorColor;
    tableView.separatorInset = _notesTableView.separatorInset;
    tableView.tableFooterView = [UIView new]; // Removes separators of empty cells
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    _searchString = searchString;
    [_searchDataSource search:searchString inIndexItem:self.indexItem];
    return YES;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (gestureRecognizer == _notesTableView.reorderGestureRecognizer)
    {
        return _sortMode == HPTagSortModeOrder;
    }
    return NO;
}

#pragma mark AGNNoteViewControllerDelegate

- (void)noteViewController:(AGNNoteViewController*)viewController didSelectIndexItem:(HPIndexItem*)indexItem
{
    if (indexItem.tag != self.indexItem.tag)
    {
        self.indexItem = indexItem;
        [self.delegate noteListViewController:self didChangeIndexItem:indexItem];
    }
}

#pragma mark Notifications

- (void)indexItemDidChangeNotification:(NSNotification*)notification
{
    if (_ignoreNotesDidChangeNotification) return; // Controller will reflect or already reflected the change
    if (self.transitioning || !_visible) return; // Changes will be reflected in viewDidAppear
    
    [self reloadNotesAnimated:YES];
}

- (void)notesDidChangeNotification:(NSNotification*)notification
{
    if (_ignoreNotesDidChangeNotification) return; // Controller will reflect or already reflected the change
    NSDictionary *userInfo = notification.userInfo;

    // Only consider updated notes. Insertions and deletions are handled in indexItemDidChangeNotification:
    NSSet *updated = userInfo[NSUpdatedObjectsKey];
    if (updated.count == 0) return;
    
    if (self.transitioning || !_visible)
    {
        [_pendingUpdatedNotes addObjectsFromArray:updated.allObjects];
        return;
    }
    
    [self reloadNotesWithUpdates:updated animated:YES];
}

- (void)tagsDidChangeNotification:(NSNotification*)notification
{
    NSDictionary *userInfo = notification.userInfo;
    NSSet *deleted = userInfo[NSDeletedObjectsKey];
    if ([deleted containsObject:self.indexItem.tag])
    {
        self.indexItem = [HPIndexItem inboxIndexItem];
    }
}

- (void)didChangeFontsNotification:(NSNotification*)notification
{
    [self applyFonts];
    [_notesTableView reloadData];
    UITableView *searchTableView = self.searchDisplayController.searchResultsTableView;
    [searchTableView reloadData];
}

- (void)didChangePreferences:(NSNotification*)notification
{
    [self applyPreferences];
}

- (void)statusNotification:(NSNotification*)notification
{
    NSString *subtitle = notification.hp_statuslocalizedMessage;
    const BOOL transient = notification.hp_statusTransient;
    [_titleView setSubtitle:subtitle animated:YES transient:transient];
}

- (void)willReplaceModelNotification:(NSNotification*)notification
{
    [self stopObserving];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPIndexItemDidChangeNotification object:_indexItem];
    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    _titleView.userInteractionEnabled = NO;
    self.searchDisplayController.active = NO;
    // TODO: Read-only mode
    _emptyTitleLabel.text = NSLocalizedString(@"iCloud sync", @"");
    _emptySubtitleLabel.text = NSLocalizedString(@"Receiving notes from iCloud…", @"");
    _listDataSource.items = @[];
    _indexItem = nil;
    [_notesTableView reloadData];
    [self updateEmptyView:YES];
}

@end
