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
{
    NSArray *previousNotes = _notes;
    _notes = [HPNoteManager sharedManager].notes;

    NSArray *indexPathsToDelete = [self indexPathsOfArray:previousNotes notInArray:_notes];
    NSArray *indexPathsToInsert = [self indexPathsOfArray:_notes notInArray:previousNotes];
    
    [_tableView beginUpdates];
    [_tableView deleteRowsAtIndexPaths:indexPathsToDelete withRowAnimation:UITableViewRowAnimationAutomatic];
    [_tableView insertRowsAtIndexPaths:indexPathsToInsert withRowAnimation:UITableViewRowAnimationAutomatic];
    [_tableView endUpdates];
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
    HPNoteTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    HPNote *note = [_notes objectAtIndex:indexPath.row];
    cell.note = note;
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    HPNote *note = [_notes objectAtIndex:indexPath.row];
    [self showNote:note];
}

@end
