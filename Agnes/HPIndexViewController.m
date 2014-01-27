//
//  HPIndexViewController.m
//  Agnes
//
//  Created by Hermes on 18/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPIndexViewController.h"
#import "HPNoteListViewController.h"
#import "HPNoteManager.h"
#import "HPTagManager.h"
#import "HPIndexItem.h"
#import "HPIndexItemTableViewCell.h"
#import "HPNote.h"
#import "HPTag.h"
#import "HPNoteViewController.h"
#import "HPRootViewController.h"
#import "MMDrawerController.h"
#import "UITableView+hp_reloadChanges.h"
#import "UIViewController+MMDrawerController.h"

@interface HPIndexViewController ()

@end

static NSString *HPIndexCellIdentifier = @"Cell";

@implementation HPIndexViewController {
    NSMutableArray *_items;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Agnes", "Index title");
    
    UINib *nib = [UINib nibWithNibName:@"HPIndexItemTableViewCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:HPIndexCellIdentifier];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 10, 0);
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fixedSpace.width = 15;
    UIBarButtonItem *addBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addBarButtonItemAction:)];
    self.navigationItem.rightBarButtonItems = @[fixedSpace, addBarButtonItem];
    
    [self reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(notesDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagsDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPTagManager sharedManager]];
}

#pragma mark - Private

- (void)reloadData
{
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[HPIndexItem inboxIndexItem]];
    
    NSArray *tags = [HPTagManager sharedManager].objects;
    { // Remove tags with only archived notes
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"ANY %K.%K == NO", NSStringFromSelector(@selector(cd_notes)), NSStringFromSelector(@selector(cd_archived))];
        tags = [tags filteredArrayUsingPredicate:predicate];
    }
    NSSortDescriptor *orderSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(order)) ascending:NO];
    NSSortDescriptor *nameSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(name)) ascending:YES];
    tags = [tags sortedArrayUsingDescriptors:@[orderSortDescriptor, nameSortDescriptor]];
    for (HPTag *tag in tags)
    {
        HPIndexItem *indexItem = [HPIndexItem indexItemWithTag:tag.name];
        [items addObject:indexItem];
    }
    
    [items addObject:[HPIndexItem archiveIndexItem]];
    [items addObject:[HPIndexItem systemIndexItem]];
    
    NSArray *previousItems = _items;
    NSArray *previousData = previousItems ? @[previousItems] : nil;
    _items = items;
    
    [self.tableView hp_reloadChangesWithPreviousData:previousData currentData:@[_items] reloadObjects:[NSSet set] keyBlock:^id<NSCopying>(HPIndexItem *indexItem) {
        return indexItem.title; // TODO: Provide a real unique id for index items
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

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
    HPIndexItem *item = [_items objectAtIndex:indexPath.row];
    return item.tag != nil;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    [_items exchangeObjectAtIndex:sourceIndexPath.row withObjectAtIndex:destinationIndexPath.row];
    NSMutableArray *tagNames = [NSMutableArray array];
    for (HPIndexItem *item in _items)
    {
        NSString *tagName = item.tag;
        if (tagName)
        {
            [tagNames addObject:tagName];
        }
    }
    [[HPTagManager sharedManager] reorderTagsWithNames:tagNames];
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    NSInteger sourceRow = sourceIndexPath.row;
    NSInteger proposedRow = proposedDestinationIndexPath.row;
    HPIndexItem *proposedIndexItem = _items[proposedRow];
    if (proposedIndexItem.tag)
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
    HPIndexItem *item = [_items objectAtIndex:indexPath.row];
    UINavigationController *centerViewController = [HPNoteListViewController controllerWithIndexItem:item];
    centerViewController.delegate = [self hp_rootViewController];
    [self.mm_drawerController setCenterViewController:centerViewController withCloseAnimation:YES completion:nil];
}

#pragma mark - Actions

- (void)addBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    UINavigationController *centerViewController = [HPNoteListViewController controllerWithIndexItem:[HPIndexItem inboxIndexItem]];
    centerViewController.delegate = [self hp_rootViewController];
    HPNoteViewController *noteViewController = [HPNoteViewController blankNoteViewControllerWithNotes:@[] indexItem:nil];
    noteViewController.delegate = (id<HPNoteViewControllerDelegate>) centerViewController.topViewController;
    [centerViewController pushViewController:noteViewController animated:NO];
    [self.mm_drawerController setCenterViewController:centerViewController withCloseAnimation:YES completion:nil];
}

- (void)notesDidChangeNotification:(NSNotification*)notification
{
    NSSet *updated = [notification.userInfo objectForKey:NSUpdatedObjectsKey];
    if (updated.count > 0)
    { // Catch archived / unarchived changes
        [self reloadData];
    }
}

- (void)tagsDidChangeNotification:(NSNotification*)notification
{
    [self reloadData];
}

@end
