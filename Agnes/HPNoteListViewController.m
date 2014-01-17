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

@interface HPNoteListViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation HPNoteListViewController {
    __weak IBOutlet UITableView *_tableView;
    NSArray *_notes;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"All Notes", @"");
    
    UIBarButtonItem *addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    self.navigationItem.rightBarButtonItem = addNoteBarButtonItem;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    
    _notes = [HPNoteManager sharedManager].notes;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _notes = [HPNoteManager sharedManager].notes;
    [_tableView reloadData];
}

#pragma mark - Actions

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self showNote:nil];
}

#pragma mark - Private

- (void)showNote:(HPNote*)note
{
    HPNoteViewController *noteViewController = [[HPNoteViewController alloc] init];
    noteViewController.note = note;
    [self.navigationController pushViewController:noteViewController animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
    return _notes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    HPNote *note = [_notes objectAtIndex:indexPath.row];
    cell.textLabel.text = note.title;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HPNote *note = [_notes objectAtIndex:indexPath.row];
    [self showNote:note];
}

@end
