//
//  HPIndexViewController.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPIndexViewController.h"
#import "AGNNoteListViewController.h"
#import "AGNExportController.h"
#import "HPNoteManager.h"
#import "HPTagManager.h"
#import "HPIndexItem.h"
#import "HPIndexItemTableViewCell.h"
#import "HPNote.h"
#import "HPTag.h"
#import "AGNRootViewController.h"
#import "HPNavigationBarToggleTitleView.h"
#import "AGNPreferencesManager.h"
#import "HPModelManager.h"
#import "MMDrawerController.h"
#import "UITableView+hp_reloadChanges.h"
#import "UIViewController+hp_modals.h"
#import "UIViewController+MMDrawerController.h"
#import "HPTracker.h"

@interface HPIndexViewController ()<UIActionSheetDelegate, AGNExportControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

static NSString *HPIndexCellIdentifier = @"Cell";

@implementation HPIndexViewController {
    NSMutableArray *_items;
    IBOutlet HPNavigationBarToggleTitleView *_titleView;
    HPIndexSortMode _sortMode;
    
    NSCache *_indexItemCache;
    HPIndexItem *_selectedIndexItem;
    
    UIActionSheet *_optionsActionSheet;
    NSInteger _optionsActionSheetUndoIndex;
    NSInteger _optionsActionSheetRedoIndex;
    NSInteger _optionsActionSheetExportIndex;
    NSInteger _optionsActionSheetExportAllIndex;
    
    AGNExportController *_exportController;
    
    BOOL _ignoreTagChanges;
}

@synthesize tableView = _tableView;

- (void)dealloc
{
    [self stopObserving];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _indexItemCache = [NSCache new];
    
    _exportController = [AGNExportController new];
    _exportController.delegate = self;
    
    {
        UIImage *image = [UIImage imageNamed:@"icon-more"];
        UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithImage:image style:UIBarButtonItemStylePlain target:self action:@selector(optionsBarButtonItemAction:)];
        self.navigationItem.rightBarButtonItem = barButton;
    }
    
    self.title = NSLocalizedString(@"Agnes", "Index title");
    self.navigationItem.titleView = _titleView;
    [_titleView setTitle:self.title];
    
    UINib *nib = [UINib nibWithNibName:@"HPIndexItemTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:HPIndexCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 10, 0);
    
    _sortMode = [AGNPreferencesManager sharedManager].indexSortMode;
    
    [self reloadData];
    if (_selectedIndexItem)
    {
        [self selectIndexItem:_selectedIndexItem];
    }
    [self startObserving];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[HPTracker defaultTracker] trackScreenWithName:@"Index"];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self hp_dismissActionSheet:&_optionsActionSheet animated:YES];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [_titleView setTitle:self.title];
}

#pragma mark Public

- (void)selectIndexItem:(HPIndexItem*)indexItem
{
    _selectedIndexItem = indexItem;
    if (!self.tableView) return;
    
    __block NSUInteger index = [_items indexOfObject:indexItem];
    if (index == NSNotFound)
    {
        [_items enumerateObjectsUsingBlock:^(HPIndexItem *currentItem, NSUInteger idx, BOOL *stop) {
            if (currentItem.tag == indexItem.tag)
            {
                index = idx;
                *stop = YES;
            }
        }];
    }
    if (index == NSNotFound) return;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionMiddle];
}

#pragma mark Private

- (void)exportAllNotes
{
    NSArray *notes = [HPNoteManager sharedManager].objects;
    NSString *title = NSLocalizedString(@"Agnes", @"");
    [_exportController exportNotes:notes title:title statusView:_titleView];
}

- (void)exportSelectedNotes
{
    if ([_selectedIndexItem canExport])
    {
        NSArray *notes = _selectedIndexItem.notes;
        NSString *title = _selectedIndexItem.exportPrefix;
        [_exportController exportNotes:notes title:title statusView:_titleView];
    }
}

- (void)reloadData
{
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[HPIndexItem inboxIndexItem]];
    NSArray *tagIndexItems = [self sortedTagIndexItems];
    [items addObjectsFromArray:tagIndexItems];
    [items addObject:[HPIndexItem archiveIndexItem]];
    [items addObject:[HPIndexItem systemIndexItem]];
    
    NSArray *previousItems = _items;
    NSArray *previousData = previousItems ? @[previousItems] : nil;
    _items = items;
    
    [self.tableView hp_reloadChangesWithPreviousData:previousData currentData:@[_items] keyBlock:^id<NSCopying>(HPIndexItem *indexItem) {
        return indexItem.title; // TODO: Provide a real unique id for index items
    } reloadBlock:nil];
}

- (NSArray*)sortedTagIndexItems
{
    NSArray *tags = [[HPTagManager sharedManager] indexTags];
    NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(name)) ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)];
    switch (_sortMode)
    {
        case HPIndexSortModeOrder:
        case HPIndexSortModeCount:
        {
            NSSortDescriptor *orderSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(order)) ascending:YES];
            tags = [tags sortedArrayUsingDescriptors:@[orderSortDescriptor, nameSortDescriptor]];
            break;
        }
        case HPIndexSortModeAlphabetical:
        {
            tags = [tags sortedArrayUsingDescriptors:@[nameSortDescriptor]];
            break;
        }
    }
    NSMutableArray *indexItems = [NSMutableArray array];
    for (HPTag *tag in tags)
    {
        HPIndexItem *indexItem = [_indexItemCache objectForKey:tag.name];
        if (!indexItem)
        {
            indexItem = [HPIndexItem indexItemWithTag:tag];
            [_indexItemCache setObject:indexItem forKey:tag.name];
        }
        [indexItems addObject:indexItem];
    }
    if (_sortMode == HPIndexSortModeCount)
    {
        NSSortDescriptor *countSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(noteCount)) ascending:NO];
        [indexItems sortUsingDescriptors:@[countSortDescriptor]];
    }
    return indexItems;
}

- (void)startObserving
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagsDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willReplaceModelNotification:) name:HPModelManagerWillReplaceModelNotification object:nil];
}

- (void)stopObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPModelManagerWillReplaceModelNotification object:nil];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    HPIndexItemTableViewCell *cell = (HPIndexItemTableViewCell*)[tableView dequeueReusableCellWithIdentifier:HPIndexCellIdentifier];
    HPIndexItem *item = [_items objectAtIndex:indexPath.row];
    cell.indexItem = item;
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_sortMode == HPIndexSortModeOrder)
    {
        HPIndexItem *item = [_items objectAtIndex:indexPath.row];
        HPTag *tag = item.tag;
        return !tag.isSystem;
    }
    else
    {
        NSString *modeString = NSStringFromIndexSortMode(_sortMode);
        [_titleView setSubtitle:modeString animated:YES transient:YES];
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"reorder_tag"];
    NSMutableArray *tags = [NSMutableArray array];
    HPIndexItem *fromIndexItem = _items[sourceIndexPath.row];
    HPIndexItem *toIndexItem = _items[destinationIndexPath.row];
    __block NSUInteger fromIndex = NSNotFound;
    __block NSUInteger toIndex = NSNotFound;
    [_items enumerateObjectsUsingBlock:^(HPIndexItem *item, NSUInteger idx, BOOL *stop) {
        if (item == fromIndexItem)
        {
            fromIndex = tags.count;
        }
        else if (item == toIndexItem)
        {
            toIndex = tags.count;
        }
        HPTag *tag = item.tag;
        if (tag && !tag.isSystem)
        {
            [tags addObject:tag];
        }
    }];
    _ignoreTagChanges = YES;
    [[HPTagManager sharedManager] reorderTags:tags exchangeObjectAtIndex:fromIndex withObjectAtIndex:toIndex];
    _ignoreTagChanges = NO;
    [_items exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    NSInteger sourceRow = sourceIndexPath.row;
    NSInteger proposedRow = proposedDestinationIndexPath.row;
    HPIndexItem *proposedIndexItem = _items[proposedRow];
    HPTag *proposedTag = proposedIndexItem.tag;
    if (!proposedTag.isSystem)
    {
        return proposedDestinationIndexPath;
    }
    else if (proposedRow > sourceRow)
    { // Archive
        return [self tableView:tableView targetIndexPathForMoveFromRowAtIndexPath:sourceIndexPath toProposedIndexPath:[NSIndexPath indexPathForRow:proposedRow - 1 inSection:0]];
    }
    else
    { // Inbox
        return [self tableView:tableView targetIndexPathForMoveFromRowAtIndexPath:sourceIndexPath toProposedIndexPath:[NSIndexPath indexPathForRow:proposedRow + 1 inSection:0]];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedIndexItem = [_items objectAtIndex:indexPath.row];
    [self.agn_rootViewController setListIndexItem:_selectedIndexItem animated:YES];
}

#pragma mark Actions

- (void)optionsBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if ([self hp_dismissActionSheet:&_optionsActionSheet animated:YES]) return;
    
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"options"];
    UIActionSheet *actionSheet = [UIActionSheet new];
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
    
    _optionsActionSheetExportIndex = -1;
    if ([_selectedIndexItem canExport])
    {
        NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Export %@", @""), _selectedIndexItem.title];
        _optionsActionSheetExportIndex = [actionSheet addButtonWithTitle:title];
    }
    
    _optionsActionSheetExportAllIndex = - 1;
    NSArray *allNotes = [HPNoteManager sharedManager].objects;
    if (allNotes.count > 0)
    {
        _optionsActionSheetExportAllIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Export All Notes", @"")];
    }
    
    if (actionSheet.numberOfButtons > 0)
    {
        _optionsActionSheet = actionSheet;
        NSInteger cancelIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"")];
        actionSheet.cancelButtonIndex = cancelIndex;
        [actionSheet showFromBarButtonItem:barButtonItem animated:YES];
    }
    // TODO: Disable options button when no options are available
}

- (IBAction)tapTitleView:(id)sender
{
    [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"toggle_tag_sort"];
    NSArray *values = @[@(HPIndexSortModeOrder), @(HPIndexSortModeAlphabetical), @(HPIndexSortModeCount)];
    NSInteger index = [values indexOfObject:@(_sortMode)];
    index = (index + 1) % values.count;
    _sortMode = [values[index] intValue];
    [AGNPreferencesManager sharedManager].indexSortMode = _sortMode;
    NSString *modeString = NSStringFromIndexSortMode(_sortMode);
    [_titleView setSubtitle:modeString animated:YES transient:YES];
    [self reloadData];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == _optionsActionSheetExportIndex)
    {
        [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"export_list"];
        [self exportSelectedNotes];
    }
    else if (buttonIndex == _optionsActionSheetExportAllIndex)
    {
        [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"export_all"];
        [self exportAllNotes];
    }
    else if (buttonIndex == _optionsActionSheetRedoIndex)
    {
        NSUndoManager *undoManager = [HPNoteManager sharedManager].context.undoManager;
        [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"redo" label:undoManager.redoActionName];
        [undoManager redo];
    }
    else if (buttonIndex == _optionsActionSheetUndoIndex)
    {
        NSUndoManager *undoManager = [HPNoteManager sharedManager].context.undoManager;
        [[HPTracker defaultTracker] trackEventWithCategory:@"user" action:@"undo" label:undoManager.undoActionName];
        [undoManager undo];
    }
    _optionsActionSheet = nil;
}

#pragma mark AGNExportControllerDelegate

- (UIViewController*)viewControllerForExportController:(AGNExportController*)exportController
{
    return self;
}

#pragma mark Notifications

- (void)tagsDidChangeNotification:(NSNotification*)notification
{
    if (_ignoreTagChanges) return;
    
    NSDictionary *userInfo = notification.userInfo;
    NSSet *deleted = [userInfo objectForKey:NSDeletedObjectsKey];
    NSSet *invalidated = [userInfo objectForKey:NSInvalidatedObjectsKey];
    NSSet *refreshed = [userInfo objectForKey:NSRefreshedObjectsKey];
    NSMutableSet *changes = [NSMutableSet set];
    [changes unionSet:deleted];
    [changes unionSet:invalidated];
    [changes unionSet:refreshed];
    for (HPTag *tag in changes)
    {
        [_indexItemCache removeObjectForKey:tag.name];
    }
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        // HACK: Give time to Core Data to process pending changes or invalidate caches. See: http://stackoverflow.com/questions/22229617/fetch-request-returns-old-data
        [self reloadData];
    }];
}

- (void)willReplaceModelNotification:(NSNotification*)notification
{
    [self stopObserving];
    _items = [NSMutableArray array];
    [self.tableView reloadData];
}

@end
