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
#import "HPNote.h"
#import "HPTag.h"
#import "MMDrawerController.h"
#import "UIViewController+MMDrawerController.h"

@interface HPIndexViewController ()

@end

static NSString *HPIndexCellIdentifier = @"Cell";

@implementation HPIndexViewController {
    NSArray *_items;
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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = NSLocalizedString(@"Agnes", "Index title");
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:HPIndexCellIdentifier];
    
    [self reloadData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tagsDidChangeNotification:) name:HPEntityManagerObjectsDidChangeNotification object:[HPNoteManager sharedManager]];
}

#pragma mark - Private

- (void)reloadData
{
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[HPIndexItem inboxIndexItem]];
    
    NSArray *tags = [HPTagManager sharedManager].objects;
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(name)) ascending:YES];
    tags = [tags sortedArrayUsingDescriptors:@[sortDescriptor]];
    for (HPTag *tag in tags)
    {
        HPIndexItem *indexItem = [HPIndexItem indexItemWithTag:tag.name];
        [items addObject:indexItem];
    }
    
    [items addObject:[HPIndexItem archiveIndexItem]];
    [items addObject:[HPIndexItem systemIndexItem]];
    
    _items = items;
    [self.tableView reloadData];
}

#pragma mark - Table view data source

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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:HPIndexCellIdentifier];
    HPIndexItem *item = [_items objectAtIndex:indexPath.row];
    cell.textLabel.text = item.title;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HPIndexItem *item = [_items objectAtIndex:indexPath.row];
    UIViewController *centerViewController = [HPNoteListViewController controllerWithIndexItem:item];
    [self.mm_drawerController setCenterViewController:centerViewController withCloseAnimation:YES completion:nil];
}

#pragma mark - Actions

- (void)tagsDidChangeNotification:(NSNotification*)notification
{
    [self reloadData];
}

@end
