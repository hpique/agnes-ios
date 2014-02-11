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
#import "HPNoteListDetailTransitionAnimator.h"
#import "HPNoteNavigationController.h"
#import "HPNoteListSearchBar.h"
#import "HPFontManager.h"
#import "UITableView+hp_reloadChanges.h"
#import "MMDrawerController.h"
#import "MMDrawerBarButtonItem.h"
#import "UIViewController+MMDrawerController.h"
#import "UIColor+iOS7Colors.h"
#import "UIImage+hp_utils.h"
#import <MessageUI/MessageUI.h>

static NSString* HPNoteListTableViewCellReuseIdentifier = @"Cell";

@interface HPNoteListViewController () <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate, HPNoteViewControllerDelegate, UISearchDisplayDelegate>

@end

@implementation HPNoteListViewController {
    __weak IBOutlet HPReorderTableView *_notesTableView;
    NSMutableArray *_notes;
    
    BOOL _searching;
    NSString *_searchString;
    NSArray *_searchResults;
    NSArray *_archivedSearchResults;
    __weak IBOutlet HPNoteListSearchBar *_searchBar;
    
    IBOutlet UIView *_titleView;
    __weak IBOutlet UILabel *_sortModeLabel;
    __weak IBOutlet UILabel *_titleLabel;
    UIFont *_titleLabelFont;
    
    HPTagSortMode _sortMode;
    BOOL _userChangedSortMode;
    
    UIBarButtonItem *_addNoteBarButtonItem;
    
    HPNoteExporter *_noteExporter;
    
    NSInteger _optionsActionSheetUndoIndex;
    NSInteger _optionsActionSheetRedoIndex;
    NSInteger _optionsActionSheetExportIndex;
    
    __weak IBOutlet UIView *_emptyListView;
    __weak IBOutlet UILabel *_emptyTitleLabel;
    __weak IBOutlet UILabel *_emptySubtitleLabel;
    __weak IBOutlet NSLayoutConstraint *_emptyCenterYTitleLabelLayoutConstraint;
    
    NSIndexPath *_indexPathOfSelectedNote;
    BOOL _ignoreNotesDidChangeNotification;
    BOOL _visible;
    NSMutableSet *_pendingUpdatedNotes;
    
    NSTimer *_restoreTitleTimer;
}

@synthesize indexPathOfSelectedNote = _indexPathOfSelectedNote;
@synthesize transitioning = _transitioning;
@synthesize wantsDefaultTransition = _wantsDefaultTransition;

- (void)dealloc
{
    [_restoreTitleTimer invalidate];
    [self stopObserving];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _pendingUpdatedNotes = [NSMutableSet set];
    
    {
        _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
        MMDrawerBarButtonItem *drawerBarButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(drawerBarButtonAction:)];
        self.navigationItem.leftBarButtonItem = drawerBarButton;
        self.navigationItem.titleView = _titleView;
        self.navigationItem.rightBarButtonItems = @[_addNoteBarButtonItem];
    }
    
    UINib *nib = [UINib nibWithNibName:@"HPNoteListTableViewCell" bundle:nil];
    [_notesTableView registerNib:nib forCellReuseIdentifier:HPNoteListTableViewCellReuseIdentifier];
    _notesTableView.delegate = self;
    [_notesTableView setContentOffset:CGPointMake(0,self.searchDisplayController.searchBar.frame.size.height) animated:NO];
    
    {
        UIImage *image = [[UIImage imageNamed:@"icon-more"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_searchBar.actionButton setImage:image forState:UIControlStateNormal];
        UIImage *imageAlt = [[UIImage imageNamed:@"icon-more-alt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [_searchBar.actionButton setImage:imageAlt forState:UIControlStateHighlighted];
        _searchBar.actionButton.frame = CGRectMake(0, 0, MAX(image.size.width, 40), _searchBar.frame.size.height);
        [_searchBar.actionButton addTarget:self action:@selector(optionsButtonItemAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    {
        UISearchBar *searchBar = self.searchDisplayController.searchBar;
        searchBar.keyboardType = UIKeyboardTypeTwitter;
        searchBar.translucent = YES;
        searchBar.backgroundImage = [UIImage hp_imageWithColor:[UIColor whiteColor] size:CGSizeMake(1, 1)];
        searchBar.autocorrectionType = UITextAutocorrectionTypeNo; // HACK: See: http://stackoverflow.com/questions/8608529/autocorrect-in-uisearchbar-interferes-when-i-hit-didselectrowatindexpath
    }
    
    [self applyNavigationBarColors];
    [self applyNavigationBarFonts];
    
    [self updateNotes:NO /* animated */ reloadNotes:[NSSet set]];
    [self updateIndexItem];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeFontsNotification:) name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangePreferencesNotification:) name:HPPreferencesManagerDidChangePreferencesNotification object:[HPPreferencesManager sharedManager]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _visible = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.transitioning)
    {
        [self updateNotes:animated reloadNotes:[NSSet set]];
    }
    self.transitioning = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.transitioning = NO;
    _visible = NO;
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
    HPNoteNavigationController *controller = [[HPNoteNavigationController alloc] initWithRootViewController:noteListViewController];
    return controller;
}

#pragma mark - Actions

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    HPNoteViewController *noteViewController = [HPNoteViewController blankNoteViewControllerWithNotes:_notes indexItem:self.indexItem];
    noteViewController.delegate = self;
    [self.navigationController pushViewController:noteViewController animated:YES];
}

- (void)archiveNoteInCell:(HPNoteListTableViewCell*)cell
{
    [self removeNoteInCell:cell modelBlock:^{
        [[HPNoteManager sharedManager] archiveNote:cell.note];
    }];
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

- (void)trashNoteInCell:(HPNoteListTableViewCell*)cell
{
    [self removeNoteInCell:cell modelBlock:^{
        [[HPNoteManager sharedManager] trashNote:cell.note];
    }];
}

- (void)unarchiveNoteInCell:(HPNoteListTableViewCell*)cell
{
    [self removeNoteInCell:cell modelBlock:^{
        [[HPNoteManager sharedManager] unarchiveNote:cell.note];
    }];
}

- (void)notesDidChangeNotification:(NSNotification*)notification
{
    if (_ignoreNotesDidChangeNotification) return; // Controller will reflect or already reflected the change
    NSDictionary *userInfo = notification.userInfo;
    NSSet *updated = [userInfo objectForKey:NSUpdatedObjectsKey];
    
    if (self.transitioning || !_visible)
    {
        [_pendingUpdatedNotes addObjectsFromArray:updated.allObjects];
        return;
    }
    
    [self updateNotes:YES /* animated */ reloadNotes:updated];
}

- (void)drawerBarButtonAction:(MMDrawerBarButtonItem*)barButtonItem
{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)optionsButtonItemAction:(id)sender
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
    _userChangedSortMode = YES;
    NSArray *values = self.indexItem.allowedSortModes;
    NSInteger index = [values indexOfObject:@(_sortMode)];
    index = (index + 1) % values.count;
    _sortMode = [values[index] intValue];
    self.indexItem.sortMode = _sortMode;
    [self updateNotes:YES /* animated */ reloadNotes:[NSSet set]];
    [self updateSortMode:YES /* animated */];
}

#pragma mark - Private

- (void)applyNavigationBarColors
{
    HPPreferencesManager *preferences = [HPPreferencesManager sharedManager];
    UIColor *barForegroundColor = preferences.barForegroundColor;
    _titleLabel.textColor = barForegroundColor;
    _sortModeLabel.textColor = barForegroundColor;
}

- (void)applyNavigationBarFonts
{
    _titleLabel.font = [HPFontManager sharedManager].fontForNavigationBarTitle;
    _sortModeLabel.font = [HPFontManager sharedManager].fontForNavigationBarDetail;
    _titleLabelFont = _titleLabel.font;
}

- (void)alertErrorWithTitle:(NSString*)title message:(NSString*)message
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"") otherButtonTitles:nil];
    [alertView show];
}

- (void)changeModel:(void (^)())modelBlock changeView:(void (^)())viewBlock
{
    _ignoreNotesDidChangeNotification = YES;
    modelBlock();
    viewBlock();
    _ignoreNotesDidChangeNotification = NO;
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



- (void)removeNoteInCell:(HPNoteListTableViewCell*)cell modelBlock:(void (^)())block
{
    NSIndexPath *indexPath = [_notesTableView indexPathForCell:cell];
    [self changeModel:block changeView:^{
        [_notes removeObjectAtIndex:indexPath.row];
        [_notesTableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self updateEmptyView:YES];
    }];
}

- (void)restoreNavigationBarTitle
{
    [UIView transitionWithView:_titleView duration:0.2 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        _titleLabel.font = _titleLabelFont;
        _titleLabel.text = self.title;
        _sortModeLabel.text = nil;
    } completion:^(BOOL finished) {}];
}

- (void)stopObserving
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPPreferencesManagerDidChangePreferencesNotification object:[HPPreferencesManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPFontManagerDidChangeFontsNotification object:[HPFontManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
}

- (void)updateEmptyView:(BOOL)animated
{
    BOOL empty = _notes.count == 0;
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

- (void)updateNotes:(BOOL)animated reloadNotes:(NSSet*)reloadNotes
{
    reloadNotes = [reloadNotes setByAddingObjectsFromSet:_pendingUpdatedNotes];
    [_pendingUpdatedNotes removeAllObjects];
    
    NSArray *previousNotes = _notes;
    NSArray *notes = self.indexItem.notes;
    notes = [HPNoteManager sortedNotes:notes mode:_sortMode tag:self.indexItem.tag];
    _notes = [NSMutableArray arrayWithArray:notes];
    
    if (animated)
    {
        NSArray *previousData = previousNotes ? @[previousNotes] : nil;
        [_notesTableView hp_reloadChangesWithPreviousData:previousData currentData:@[_notes] keyBlock:^id<NSCopying>(HPNote *note) {
            return note.objectID;
        } reloadBlock:^BOOL(HPNote *note) {
            // Only reload remaining notes if the cell height changed
            if (![reloadNotes containsObject:note]) return NO;
            NSInteger index = [previousNotes indexOfObject:note];
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            if (![[_notesTableView indexPathsForVisibleRows] containsObject:indexPath]) return NO;
            UITableViewCell *cell = [_notesTableView cellForRowAtIndexPath:indexPath];
            return cell.frame.size.height != [HPNoteTableViewCell heightForNote:note width:cell.frame.size.width tagName:self.indexItem.tag.name];
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
        NSArray *previousSearchResults = _searchResults;
        NSArray *previousArchivedSearchResults = _archivedSearchResults;
        NSArray *previousData = _searchResults == nil || _archivedSearchResults == nil ? nil : @[previousSearchResults, previousArchivedSearchResults];

        _searchResults = [self notesWithSearchString:_searchString archived:NO];
        _archivedSearchResults = [self notesWithSearchString:_searchString archived:YES];
        
        [searchTableView hp_reloadChangesWithPreviousData:previousData
                                              currentData:@[_searchResults, _archivedSearchResults]
                                                 keyBlock:^id<NSCopying>(HPNote *note) {
                                                     return note.objectID;
                                              } reloadBlock:^BOOL(HPNote *note) {
                                                  return [reloadNotes containsObject:note];
                                              }];
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
    _emptyTitleLabel.text = self.indexItem.emptyTitle;
    _emptySubtitleLabel.text = self.indexItem.emptySubtitle;
    _emptyTitleLabel.font = self.indexItem.emptyTitleFont;
    _emptySubtitleLabel.font = self.indexItem.emptySubtitleFont;
    _emptyCenterYTitleLabelLayoutConstraint.constant = [_emptySubtitleLabel intrinsicContentSize].height;
    self.searchDisplayController.searchBar.placeholder = [NSString stringWithFormat:NSLocalizedString(@"Search %@", @""), self.title];
    
    _addNoteBarButtonItem.enabled = !self.indexItem.disableAdd;
    _sortMode = self.indexItem.sortMode;
    [self updateSortMode:NO /* animated */];
}

- (void)updateSortMode:(BOOL)animated
{
    [_restoreTitleTimer invalidate];
    NSString *criteriaDescription = [self descriptionForSortMode:_sortMode];
    NSTimeInterval duration = animated ? 0.2 : 0;
    
    [UIView transitionWithView:_titleView duration:duration options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        BOOL landscape = UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
        if (landscape)
        {
            _titleLabel.font = [_titleLabelFont fontWithSize:_titleLabelFont.pointSize * 0.75];
            _titleLabel.text = criteriaDescription;
            _sortModeLabel.text = @"";
        }
        else
        {
            _titleLabel.font = _titleLabelFont;
            _titleLabel.text = self.title;
            _sortModeLabel.text = criteriaDescription;
        }
    } completion:^(BOOL finished) {}];
    
    const HPTagSortMode sortMode = _sortMode;
    [_notesTableView.visibleCells enumerateObjectsUsingBlock:^(HPNoteListTableViewCell *cell, NSUInteger idx, BOOL *stop) {
        [cell setDetailMode:sortMode animated:animated];
    }];
    
    CGFloat offsetY = _notesTableView.tableHeaderView.bounds.size.height - _notesTableView.contentInset.top;
    [_notesTableView setContentOffset:CGPointMake(0, offsetY) animated:animated];

    _restoreTitleTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(restoreNavigationBarTitle) userInfo:nil repeats:NO];
}

- (void)showNote:(HPNote*)note in:(NSArray*)notes
{
    HPNoteViewController *noteViewController = [HPNoteViewController noteViewControllerWithNote:note notes:_notes indexItem:self.indexItem];
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

- (NSArray*)notesWithSearchString:(NSString*)searchString archived:(BOOL)archived
{
    if (searchString.length < 2) return @[];
    
    // TODO: Move to HPNoteManager
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.%@ contains[cd] %@ && SELF.%@ == %d",
                              NSStringFromSelector(@selector(text)),
                              searchString,
                              NSStringFromSelector(@selector(archived)),
                              archived ? 1 : 0];
    NSArray *unfilteredNotes = archived ? [self.indexItem notes:YES] : _notes;
    if (!unfilteredNotes) unfilteredNotes = @[];
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
    cell.firstTrigger = 1.0f/3.0f;
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
        case MCSwipeTableViewCellState4:
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
    HPNoteTableViewCell *cell = (HPNoteTableViewCell*)[tableView dequeueReusableCellWithIdentifier:HPNoteListTableViewCellReuseIdentifier forIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSArray *objects = [self tableView:tableView notesInSection:indexPath.section];
    HPNote *note = [objects objectAtIndex:indexPath.row];
    if (self.searchDisplayController.searchResultsTableView == tableView)
    {
        HPNoteSearchTableViewCell *searchCell = (HPNoteSearchTableViewCell*)cell;
        searchCell.searchText = _searchString;
    }
    else
    {
        HPNoteListTableViewCell *noteCell = (HPNoteListTableViewCell*)cell;
        noteCell.separatorInset = UIEdgeInsetsZero;
        noteCell.reuseSwipeViews = YES;
        noteCell.shouldAnimateIcons = NO;
        
        __weak id weakSelf = self;
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
        }
    }
    [cell setNote:note ofTagNamed:self.indexItem.tag.name detailMode:_sortMode];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.searchDisplayController.searchResultsTableView == tableView) return NO;
    return _sortMode == HPTagSortModeOrder;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    NSInteger index = sourceIndexPath.row;
    id object = _notes[index];
    [_notes removeObjectAtIndex:sourceIndexPath.row];
    [_notes insertObject:object atIndex:destinationIndexPath.row];
    _ignoreNotesDidChangeNotification = YES;
    HPTag *tag = self.indexItem.tag;
    [[HPNoteManager sharedManager] reorderNotes:_notes tagName:tag.name];
    _ignoreNotesDidChangeNotification = NO;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *objects = [self tableView:tableView notesInSection:indexPath.section];
    HPNote *note = [objects objectAtIndex:indexPath.row];
    NSString *tagName = nil;
    if (_notesTableView == tableView)
    { // Search doesn't care about tags
        HPTag *tag = self.indexItem.tag;
        tagName = tag.name;
    }
    return [HPNoteTableViewCell estimatedHeightForNote:note inTagNamed:tagName];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *objects = [self tableView:tableView notesInSection:indexPath.section];
    HPNote *note = [objects objectAtIndex:indexPath.row];
    CGFloat width = tableView.bounds.size.width;
    if (tableView == _notesTableView)
    {
        HPTag *tag = self.indexItem.tag;
        return [HPNoteTableViewCell heightForNote:note width:width tagName:tag.name];
    }
    else
    {
        return [HPNoteSearchTableViewCell heightForNote:note width:width searchText:_searchString];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _indexPathOfSelectedNote = indexPath;
    NSArray *objects = [self tableView:tableView notesInSection:indexPath.section];
    HPNote *note = [objects objectAtIndex:indexPath.row];
    [self showNote:note in:objects];
}

#pragma mark - UISearchDisplayDelegate

- (void) searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    self.title = NSLocalizedString(@"Search", @"");
    [_searchBar setWillBeginSearch];
    _searching = YES;
}

- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [_searchBar setWillEndSearch];
}

- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller
{
    self.title = self.indexItem.title;
    _searching = NO;
    _searchString = nil;
    _searchResults = nil;
    _archivedSearchResults = nil;
}

- (void)searchDisplayController:(UISearchDisplayController *)controller didLoadSearchResultsTableView:(UITableView *)tableView
{
    UINib *nib = [UINib nibWithNibName:@"HPNoteSearchTableViewCell" bundle:nil];
    [tableView registerNib:nib forCellReuseIdentifier:HPNoteListTableViewCellReuseIdentifier];
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    _searchString = searchString;
    _searchResults = [self notesWithSearchString:searchString archived:NO];
    _archivedSearchResults = [self notesWithSearchString:searchString archived:YES];
    return YES;
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
        return _sortMode == HPTagSortModeOrder;
    }
    return NO;
}

#pragma mark - HPNoteViewControllerDelegate

- (void)noteViewController:(HPNoteViewController*)viewController shouldReturnToIndexItem:(HPIndexItem*)indexItem
{
    self.indexItem = indexItem;
}

#pragma mark - Notifications

- (void)didChangeFontsNotification:(NSNotification*)notification
{
    [self applyNavigationBarFonts];
    [_notesTableView reloadData];
    UITableView *searchTableView = self.searchDisplayController.searchResultsTableView;
    [searchTableView reloadData];
}

- (void)didChangePreferencesNotification:(NSNotification*)notification
{
    [self applyNavigationBarColors];
}

@end
