//
//  HPNoteViewController.m
//  Agnes
//
//  Created by Hermes on 16/01/14.
//  Copyright (c) 2014 Hermes Pique. All rights reserved.
//

#import "HPNoteViewController.h"
#import "HPNote.h"
#import "HPNoteManager.h"
#import "HPBaseTextStorage.h"
#import "PSPDFTextView.h"

@interface HPNoteViewController () <UITextViewDelegate, UIActionSheetDelegate>

@end

@implementation HPNoteViewController {
    UITextView *_bodyTextView;
    UIEdgeInsets _originalBodyTextViewInset;
    NSTextStorage *_bodyTextStorage;

    UIBarButtonItem *_actionBarButtonItem;
    UIBarButtonItem *_addNoteBarButtonItem;
    UIBarButtonItem *_archiveBarButtonItem;
    UIBarButtonItem *_doneBarButtonItem;
    UIBarButtonItem *_trashBarButtonItem;
    UIBarButtonItem *_unarchiveBarButtonItem;
    
    NSInteger _noteIndex;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionBarButtonItemAction:)];
    _addNoteBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addNoteBarButtonItemAction:)];
    _archiveBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(archiveBarButtomItemAction:)];
    _doneBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonItemAction:)];
    _trashBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(trashBarButtonItemAction:)];
    _unarchiveBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(unarchiveBarButtomItemAction:)];

    self.navigationItem.rightBarButtonItems = @[_addNoteBarButtonItem, _actionBarButtonItem];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
 
    {
        _bodyTextStorage= [HPBaseTextStorage new];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        CGSize containerSize = CGSizeMake(self.view.bounds.size.width,  CGFLOAT_MAX);
        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:containerSize];
        container.widthTracksTextView = YES;
        [layoutManager addTextContainer:container];
        [_bodyTextStorage addLayoutManager:layoutManager];
        
        _bodyTextView = [[PSPDFTextView alloc] initWithFrame:self.view.bounds textContainer:container];
        _bodyTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _bodyTextView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _bodyTextView.dataDetectorTypes = UIDataDetectorTypeLink | UIDataDetectorTypePhoneNumber;
        _bodyTextView.delegate = self;
        [self.view addSubview:_bodyTextView];
    }
    
    [self displayNote];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.navigationController.toolbarHidden = YES;
    if (self.note.empty)
    {
        [[HPNoteManager sharedManager] removeNote:self.note];
    }
}

#pragma mark - Public

- (void)setNote:(HPNote *)note
{
    _note = note;
    _noteIndex = [self.notes indexOfObject:self.note];
}

- (void)setNotes:(NSMutableArray *)notes
{
    _notes = notes;
    if (self.note)
    {
        _noteIndex = [self.notes indexOfObject:self.note];
    }
}

#pragma mark - Private

- (void)displayNote
{
    _bodyTextView.text = self.note.text;
    self.note.views++;
    [self updateToolbar:NO /* animated */];
}

- (void)finishEditing
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)trashNote
{
    [[HPNoteManager sharedManager] removeNote:self.note];
    [self finishEditing];
}

- (void)changeNoteWithTransitionOptions:(UIViewAnimationOptions)options
{
    [self.view endEditing:YES];
    [UIView transitionWithView:self.view duration:1.0 options:options animations:^{
        [self displayNote];
    } completion:^(BOOL finished) {
    }];
}

- (void)emptyNote
{
    _note = nil;
    if (self.notes != nil && _noteIndex < self.notes.count)
    {
        _noteIndex++;
    }
    [self changeNoteWithTransitionOptions:UIViewAnimationOptionTransitionCurlUp];
}

- (void)updateToolbar:(BOOL)animated
{
    NSArray *toolbarItems;
    if (self.note)
    {
        UIBarButtonItem *rightBarButtonItem = self.note.archived ? _unarchiveBarButtonItem : _archiveBarButtonItem;
        UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        toolbarItems = @[_trashBarButtonItem, flexibleSpace, rightBarButtonItem];
    } else {
        toolbarItems = @[_trashBarButtonItem];
    }
    [self setToolbarItems:toolbarItems animated:animated];
}

#pragma mark - Actions

- (void)actionBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    NSArray *activityItems = @[self.note.text];
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)archiveBarButtomItemAction:(UIBarButtonItem*)barButtonItem
{
    self.note.archived = YES;
    [self updateToolbar:YES /* animated */];
}

- (void)addNoteBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self emptyNote];
}

- (void)doneBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    [self.view endEditing:YES];
}

- (IBAction)swipeRightAction:(id)sender
{
    if (self.notes != nil && _noteIndex > 0)
    {
        NSInteger previousIndex = _noteIndex - 1;
        _note = self.notes[previousIndex];
        _noteIndex = previousIndex;
        [self changeNoteWithTransitionOptions:UIViewAnimationOptionTransitionCurlDown];
    }
    else
    {
        [self finishEditing];
    }
}

- (IBAction)swipeLeftAction:(id)sender
{
    NSInteger nextIndex = _noteIndex + 1;
    if (self.notes != nil && nextIndex < self.notes.count)
    {
        _note = self.notes[nextIndex];
        _noteIndex = nextIndex;
        [self changeNoteWithTransitionOptions:UIViewAnimationOptionTransitionCurlUp];
    }
    else
    {
        [self emptyNote];
    }
}

- (void)trashBarButtonItemAction:(UIBarButtonItem*)barButtonItem
{
    if (!self.note || self.note.empty)
    {
        [self trashNote];
    }
    else
    {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:@"Delete Note" otherButtonTitles:nil];
        [actionSheet showInView:self.view];
    }
}

- (void)unarchiveBarButtomItemAction:(UIBarButtonItem*)barButtonItem
{
    self.note.archived = NO;
    [self updateToolbar:YES /* animated */];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    if (!self.note)
    {
        _note = [[HPNoteManager sharedManager] blankNote];
        self.note.views++;
        if (self.notes.count == 0)
        {
             _notes = [NSMutableArray array];
            _noteIndex = 0;
        }
        [self.notes insertObject:self.note atIndex:_noteIndex];
        [self updateToolbar:YES /* animated */];
    }
    else
    {
        self.note.modifiedAt = [NSDate date];
    }
    self.note.text = textView.text;
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self.navigationItem setRightBarButtonItems:@[_doneBarButtonItem, _actionBarButtonItem] animated:YES];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self.navigationItem setRightBarButtonItems:@[_addNoteBarButtonItem, _actionBarButtonItem] animated:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        [self trashNote];
    }
}


#pragma mark - Notifications

- (void)keyboardDidShowNotification:(NSNotification*)notification
{
    NSDictionary *info = notification.userInfo;
    CGSize keyboardSize = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;
    
    _originalBodyTextViewInset = _bodyTextView.contentInset;
    _bodyTextView.contentInset = UIEdgeInsetsMake(_originalBodyTextViewInset.top, _originalBodyTextViewInset.left, keyboardSize.height, _originalBodyTextViewInset.right);
    _bodyTextView.scrollIndicatorInsets = _bodyTextView.contentInset;
}

- (void)keyboardWillHideNotification:(NSNotification*)notification
{
    _bodyTextView.contentInset = _originalBodyTextViewInset;
    _bodyTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

@end
